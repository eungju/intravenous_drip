defmodule Webhook do
  @spec signature(binary, binary) :: binary
  def signature(secret, body) do
    :crypto.hmac(:sha256, secret, body) |> Base.encode64
  end

  @spec validate_signature(binary, binary, binary) :: boolean
  def validate_signature(secret, body, signature) do
    signature(secret, body) == signature
  end
end
