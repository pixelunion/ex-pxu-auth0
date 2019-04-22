defmodule PxUAuth0.UserFromAuth do
  @moduledoc """
  Retrieve the user information from an auth request
  """
  require Logger

  alias PxUAuth0.UserToken
  alias Ueberauth.Auth

  @dev_credentials %{id: 1, name: "dev", avatar: "", groups: ["Apps Dev"], claims: %{}}

  def find_or_create(%Auth{provider: :identity} = auth), do: dev_user_authorization(auth)
  def find_or_create(%Auth{} = auth), do: {:ok, basic_info(auth)}

  defp dev_user_authorization(%{extra: %{raw_info: %{"name" => name, "password" => password}}}) do
    if name == System.get_env("LOGIN_NAME") and password == System.get_env("LOGIN_PASSWORD") do
      {:ok, @dev_credentials}
    else
      {:error, "Incorrect Name or Password"}
    end
  end

  defp basic_info(auth) do
    {:ok, claims} = extract_claims(auth)

    %{
      id: auth.uid,
      name: Map.get(claims, "name"),
      avatar: Map.get(claims, "picture"),
      groups: Map.get(claims, "#{UserToken.claim_namespace()}groups", []),
      claims: claims
    }
  end

  defp extract_claims(%Auth{
         credentials: %Ueberauth.Auth.Credentials{other: %{"id_token" => jwt_token}}
       }) do
    case UserToken.verify_and_validate(jwt_token, UserToken.signer()) do
      {:ok, _} = claims ->
        claims

      res ->
        Logger.info("failed to validate JWT: #{inspect(res)}")
    end
  end
end
