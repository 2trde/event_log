defmodule EventLog do
  alias EventLog.Blacklist
  alias EventLog.ProcessMap

  defmacro __using__(_) do
    quote do
      require EventLog
    end
  end

  defmacro measure(action, block) do
    quote do
      start_time = :erlang.system_time()
      result = unquote(block[:do])
      duration = (:erlang.system_time() - start_time) / 1_000_000_000
      EventLog.log("measurement", action: unquote(action), duration: duration)
      result
    end
  end

  def start_context(key), do: ProcessMap.start(key)
  def finish_context(), do: ProcessMap.finish()

  def log(name, user, params) when is_list(params), do: log(name, user, Enum.into(params, %{}))

  def log(name, %{id: user_id, seller_id: seller_id}, params) do
    params =
      params
      |> Map.put(:user_id, user_id)
      |> Map.put(:seller_id, seller_id)

    log(name, params)
  end

  def log(name, _user, params) do
    log(name, params)
  end

  def log(name, params) when is_list(params), do: log(name, Enum.into(params, %{}))

  def log(name, params) do
    send_es(name, curate_params(params), "event")
  end

  @spec error(any, maybe_improper_list | map) :: {:ok, any}
  def error(name, params) when is_list(params), do: error(name, Enum.into(params, %{}))

  def error(name, params) do
    params = Blacklist.clean_params(params)

    if send_to_es?() do
      send_es(name, curate_params(params), "error")
    end
  end

  def error(_kind, reason, stacktrace, custom_data, occurrence_data) do
    IO.puts("ERROR: #{inspect(reason)}")

    custom_data = Blacklist.clean_params(custom_data)
    occurrence_data = Blacklist.clean_params(occurrence_data)

    params =
      Map.merge(custom_data, occurrence_data)
      |> Map.merge(%{stacktrace: stacktrace})

    if send_to_es?() do
      send_es(reason, curate_params(params), "error")
    end
  end

  defp curate_params(params), do: Enum.into(params, %{}, &format_stacktrace/1)

  defp format_stacktrace({:stacktrace, v}) when is_list(v),
    do: {:stacktrace, Exception.format_stacktrace(v)}

  defp format_stacktrace({k, v}), do: {k, v}

  defp send_es(name, params, type) do
    if es_uri() do
      now = Timex.format!(Timex.now(), "{ISO:Extended}")
      process_id = ProcessMap.get_key()

      params =
        %{s_process_id: process_id, app: System.get_env("APP_NAME"), name: name, timestamp: now}
        |> Map.merge(params)
        |> prepare_params()

      spawn(fn ->

        try do
          creds_user = System.get_env("ES_USERNAME")
          creds_password = System.get_env("ES_PASSWORD")
          auth = if creds_user, do: [basic_auth: {creds_user, creds_password}], else: []

          HTTPoison.post!("#{es_uri()}/#{es_index(type)}/_doc", params |> Poison.encode!(), [
            {"Content-type", "application/json"}
          ], [hackney: [:insecure] ++ auth])
          |> case do
            %{status_code: code} when code in [200, 201] ->
              nil

            res ->
              IO.inspect(res, label: "response")
              local_log(params, type)
          end
        rescue
          err ->
            if Mix.env() == :prod do
              IO.inspect(err)
            end

            local_log(params, type)
        end
      end)
    else
      if System.get_env("LOG") == "true" do
        IO.puts "#{type}: #{name} (#{inspect params})"
      end
    end

    {:ok, params}
  end

  # we call inspect to ensure correct formatting for elasticsearch
  defp prepare_params(params) do
    params
    |> Enum.map(fn
      {k, v} when is_atom(k) -> {"#{k}", v}
      t -> t
    end)
    |> Enum.into(%{}, fn
      {"s3_" <> _ = k, data} ->
        ext = _get_extension_by_key(k)
        sha1 = EventLog.S3Upload.upload_data(data, ext)
        {k, "https://cdn.2trde.com/#{sha1}"}
      {k, v} when is_binary(v) -> {k, String.slice(v, 0..10_000)}
      {k, v} when is_number(v) or is_atom(v) -> {k, v}
      {k, v} -> {k, inspect(v, limit: 10_000)}
    end)
  end

  defp local_log(params, "error") do
    IO.puts("Failed to log to elasticsearch, logging locally ...")
    IO.inspect(params, label: "params")
    File.write("/tmp/events.log", "\n********************\n#{inspect(params)}", [:append])
  end

  defp local_log(_, _), do: :ok

  defp es_uri(), do: System.get_env("ES_URI")

  defp es_index("event"),
    do:
      (System.get_env("ES_INDEX_PREFIX") || "prod") <>
        "_events_" <> Timex.format!(Timex.now(), "{YYYY}_{0M}")

  defp es_index("error"),
    do:
      (System.get_env("ES_INDEX_PREFIX") || "prod") <>
        "_errors_" <> Timex.format!(Timex.now(), "{YYYY}_{0M}")

  defp send_to_es?() do
    Application.get_env(:event_log, EventLog, send_errors_to_es: true)[:send_errors_to_es]
  end

  @supported_extensions ["jpg", "jpeg", "png", "json", "xml"]
  def _get_extension_by_key(key) do
    key
    |> String.split("_")
    |> List.last()
    |> case do
      ext when ext in @supported_extensions ->
        ext
      _ -> "json"
    end
  end
end
