defmodule WebhookPlug do
  import Plug.Conn
  import Webhook

  def init(options) do
    options
  end

  def call(conn, opts) do
    if conn.method != "POST" do
      conn |> send_resp(405, "")
    else
      {:ok, secret_key} = Keyword.fetch(opts, :secret_key)
      {:ok, request_body, conn} = read_body(conn)
      signature = get_req_header(conn, "x-line-signature") |> List.first || ""
      if validate_signature(secret_key, request_body, signature) do
        {:ok, webhook_request} = Poison.Parser.parse(request_body)
        conn |> send_resp(200, "")
      else
        conn |> send_resp(400, "")
      end
    end
  end
end
