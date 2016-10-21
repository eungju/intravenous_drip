defmodule WebhookPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import Webhook

  @secret_key "SECRET_KEY"
  @opts WebhookPlug.init([secret_key: @secret_key])

  test "valid signature" do
    request_body = "{}"
    conn = conn(:post, "/callback", request_body)
    |> put_req_header("x-line-signature", signature(@secret_key, request_body))

    conn = WebhookPlug.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "no signature" do
    conn = conn(:post, "/callback", "{}")

    conn = WebhookPlug.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 400
  end
end
