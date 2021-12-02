defmodule EventLog.Blacklist do
  def clean_params(params) when is_map(params) do
    blacklisted_keys = blacklisted_keys()

    Enum.map(params, fn {k, v} ->
      clean_param({k, v}, blacklisted_keys)
    end)
    |> Enum.into(%{})
  end

  defp clean_param(param, blacklisted_keys) when is_map(param) do
    Enum.map(param, &clean_param(&1, blacklisted_keys))
    |> Enum.into(%{})
  end

  defp clean_param(param, blacklisted_keys) when is_struct(param) do
    clean_param(Map.from_struct(param), blacklisted_keys)
  end

  defp clean_param(param, blacklisted_keys) when is_list(param) do
    Enum.map(param, &clean_param(&1, blacklisted_keys))
    |> Enum.into([])
  end

  defp clean_param({key, value}, blacklisted_keys) do
    if key in blacklisted_keys do
      {key, "***REDACTED***"}
    else
      {key, clean_param(value, blacklisted_keys)}
    end
  end

  defp clean_param(p, _blacklisted_keys), do: p

  defp blacklisted_keys() do
    Application.get_env(:event_log, EventLog.Blacklist, [
      :password,
      :password_confirmation,
      :password_hash
    ])
    |> Enum.reduce([], fn elem, acc ->
      acc ++ [elem] ++ [Atom.to_string(elem)]
    end)
  end
end
