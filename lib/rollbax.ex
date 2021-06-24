defmodule EventLog.Rollbax do
  def config(c) do
    c
    |> Keyword.put(:access_token, System.get_env("ROLLBAR_ACCESS_TOKEN"))
    |> Keyword.put(:enabled, System.get_env("ROLLBAR_ENABLED", "false") == "true")
    |> Keyword.put(:environment, System.get_env("ROLLBAR_ENV"))
  end
end
