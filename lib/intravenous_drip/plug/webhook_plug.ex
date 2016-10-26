defmodule WebhookPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, opts) do
    if conn.method != "POST" do
      conn |> send_resp(405, "")
    else
      {:ok, secret_key} = Keyword.fetch(opts, :secret_key)
      {:ok, request_body, conn} = read_body(conn)
      signature = get_req_header(conn, "x-line-signature") |> List.first || ""
      if validate_signature(secret_key, request_body, signature) do
        {:ok, webhook_request} = Poison.Parser.parse(request_body)
        webhook_request["events"] |> Enum.each(&Webhook.event/1)
        conn |> send_resp(200, "")
      else
        conn |> send_resp(400, "")
      end
    end
  end

  @spec validate_signature(binary, binary, binary) :: boolean
  def validate_signature(secret, body, signature) do
    signature(secret, body) == signature
  end

  @spec signature(binary, binary) :: binary
  def signature(secret, body) do
    :crypto.hmac(:sha256, secret, body) |> Base.encode64
  end
end
