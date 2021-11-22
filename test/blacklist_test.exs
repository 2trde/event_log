defmodule EventLog.BlacklistTest do
  use ExUnit.Case

  alias EventLog.Blacklist

  test "blacklist removes nothing" do
    params = %{
      user: %{
        id: 212,
        name: "what"
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
        }
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
               }
             },
             yolo: false
           }
  end
end
