defmodule HeimdallTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts Heimdall.init([])

  doctest Heimdall

  test "it returns jwt_claims" do
    {:ok, jwt, _} = Heimdall.encode(%{test: "hello"})
    conn = conn(:get, "/", "")
           |> put_req_header("authorization", "Bearer: #{jwt}")

    conn = Heimdall.call(conn, @opts)

    assert %{"test" => "hello"} = conn.assigns.jwt_claims
  end

  test "it returns Unauthorized" do
    conn = conn(:get, "/")

    conn = Heimdall.call(conn, @opts)
    assert conn.status == 401
  end
end
