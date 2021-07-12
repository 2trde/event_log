defmodule EventLog.Rollbax do
  def config(c) do
    c
    |> Keyword.put(:access_token, System.get_env("ROLLBAR_ACCESS_TOKEN"))
    |> Keyword.put(:enabled, System.get_env("ROLLBAR_ENABLED", "false") == "true")
    |> Keyword.put(:environment, System.get_env("ROLLBAR_ENV"))
  end

  def prep_params(params) do
    params
    |> Enum.map(fn {k, v} ->
      {k, prep_param(v)}
    end)
    |> Enum.into(%{})
  end

  def prep_param(p) when is_number(p), do: p
  def prep_param(p) when is_binary(p), do: p
  def prep_param(p) when is_boolean(p), do: p
  def prep_param(p), do: inspect(p)
end
