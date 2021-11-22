defmodule EventLog.BlacklistTest do
  use ExUnit.Case

  alias EventLog.Blacklist

  test "blacklist removes nothing" do
    params = %{
      user: %{
        id: 212,
        name: "what",
        list_normal: [1, 2, 3, 4],
        list: [yolo: false]
      },
      yolo: false
    }

    assert Blacklist.clean_params(params) == params
  end

  test "blacklist removes password stuff" do
    params = %{
      user: %{
        id: 212,
        name: "what",
        password: "SECRET",
        nested: %{
          password_confirmation: "SECRET"
        },
        list: [password: "SECRET"]
      },
      yolo: false
    }

    assert Blacklist.clean_params(params) == %{
             user: %{
               id: 212,
               name: "what",
               password: "***REDACTED***",
               nested: %{
                 password_confirmation: "***REDACTED***"
               },
               list: [password: "***REDACTED***"]
             },
             yolo: false
           }
  end
end
