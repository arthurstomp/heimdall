defmodule Heimdall do
  @moduledoc """
    Heimdall is a "melange" of a Plug and a wrapper around Joken to decode
  JWT keys.
  """
  import Plug.Conn

  alias Heimdall.Token

  require Logger

	@doc """
    Identity function - Just return its parameter.

    ## Examples

      iex> Heimdall.init(["hello"])
      ["hello"]
  """
  @spec init(list) :: list
  def init(opts), do: opts

	@doc """
    It assigns extracts jwt claims and assign those to :jwt_claims
  at conn. Or halts conn with status 401.
  """
  @spec call(Plug.Conn.t, list) :: Plug.Conn.t
  def call(conn,_opts) do
    case conn |> extract_jwt |> decode do
      {:ok, claims} -> assign(conn, :jwt_claims, claims)
      {:error, _errors} -> put_status(conn, 401) |> halt
    end
  end

  @spec extract_jwt(Plug.Conn.t) :: binary | nil
  defp extract_jwt(conn) do
    case conn |> authorization_header do
      {"authorization", raw_jwt} -> raw_jwt |> parse_header
      _ -> nil
    end
  end

  @spec authorization_header(Plug.Conn.t) :: tuple
  defp authorization_header(conn) do
    conn.req_headers
    |> Enum.filter(&({"authorization", _} = &1))
    |> List.first
  end

  @spec parse_header(binary) :: binary | nil
  defp parse_header(raw_jwt) do
    case raw_jwt |> String.split |> Enum.fetch(1) do
      {:ok, jwt} -> jwt
      _ -> nil
    end
  end

  @doc """
    Encode claims into jwt.
    
    ## Examples
        iex> %{name: "test"}
        ...> |> Heimdall.encode
        ...> |> (fn({:ok, _, _}) -> :ok end).()
        :ok 
  """
	@spec encode(keyword | nil) :: {atom, binary, keyword} | {atom, binary}
  def encode(nil), do: {:error, "cannot encode nil"}
  def encode(claims), do: Token.generate_and_sign(claims)

  @doc """
    Decode jwt token.

    ## Examples
    
        iex> %{name: "test"}
        ...> |> Heimdall.encode
        ...> |> (fn({_, jwt, _}) -> jwt end).()
        ...> |> Heimdall.decode
        ...> |> (fn({:ok, claims}) -> Map.get(claims, "name") end).()
        "test"
        
        iex> Heimdall.decode(nil)
        {:error, :not_valid}

        iex> Heimdall.decode("...")
        {:error, :signature_error}
  """
  @spec decode(binary) :: {atom, keyword | binary}
  def decode(nil), do: {:error, :not_valid}
  def decode(jwt), do: Token.verify_and_validate(jwt)
end
