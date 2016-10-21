defmodule WebhookPlug do
  import Plug.Conn

  def init(options) do
      options
  end

  def call(conn, opts) do
    secret_key = Keyword.get(opts, :secret_key)
    signature = get_req_header(conn, "x-line-signature")
    {:ok, request_body, conn} = read_body(conn)
    if Webhook.validate_signature(secret_key, request_body, signature) do
      conn |> send_resp(200, "")
    else
      conn |> send_resp(400, "")
    end
  end
end