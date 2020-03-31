defmodule EventLogTest do
  use ExUnit.Case
  
  test "logging to elasticsearch" do
    me = self()
    :meck.expect(HTTPoison, :post!, fn url, body, _header ->
      send me, {:post!, url, body}
      %HTTPoison.Response{status_code: 200}
    end)
    
    EventLog.log("foo", %{id: 1, seller_id: 2}, %{foo: "image.jpg", bar: "value"})
    month = Timex.format!(Timex.now, "{YYYY}_{0M}")
    assert_receive {:post!, url, body}
    assert url == "http://127.0.0.1:9200/prod_events_#{month}"
    assert %{"app" => nil, "bar" => "value", "foo" => "image.jpg", "name" => "foo", "seller_id" => 2, "timestamp" => _, "user_id" => 1}
             = body |> Poison.decode!
  end
end
