defmodule WebhookPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import WebhookPlug

  @secret_key "SECRET_KEY"
  @opts WebhookPlug.init([secret_key: @secret_key])

  test "do not allow all other methods except POST" do
    conn = conn(:get, "/callback", ~s({"events": []}))

    conn = WebhookPlug.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 405
  end

  test "accept if the request has valid signature" do
    request_body = ~s({"events": []})
    conn = conn(:post, "/callback", request_body)
    |> put_req_header("x-line-signature", signature(@secret_key, request_body))

    conn = WebhookPlug.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "reject a request if the request has no signature" do
    conn = conn(:post, "/callback", ~s({"events": []}))

    conn = WebhookPlug.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 400
  end

  test "expect that requests contain events" do
    request_body = ~s({"events": []})
    conn = conn(:post, "/callback", request_body)
    |> put_req_header("x-line-signature", signature(@secret_key, request_body))

    conn = WebhookPlug.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  defmodule BufferWebhookEventHandler do
    use GenEvent

    def init([]), do: {:ok, []}

    def handle_event({:event, event}, state), do: {:ok, [event|state]}

    def handle_call(:events, state), do: {:ok, Enum.reverse(state), state}

    def subscribe(pid) do
      handler = __MODULE__
      GenEvent.add_handler(pid, handler, [])
      handler
    end

    def events(pid, handler), do: GenEvent.call(pid, handler, :events)
  end

  test "publish events through Webhook" do
    {:ok, webhook} = Webhook.start_link()
    handler = BufferWebhookEventHandler.subscribe(webhook)

    request_body = ~s({"events": [{"type": "message"}, {"type": "postback"}]})
    conn = conn(:post, "/callback", request_body)
    |> put_req_header("x-line-signature", signature(@secret_key, request_body))

    conn = WebhookPlug.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200

    assert BufferWebhookEventHandler.events(webhook, handler) == [%{"type" => "message"}, %{"type" => "postback"}]
  end
end
