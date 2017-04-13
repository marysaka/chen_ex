defmodule ChenEx.User do
  defstruct [:id, :name, :nickname, :email, :password_hash, :desc]

  def get(name, type \\ :raw) do
    case ChenEx.Helper.Riak.get("users", name) do
      nil -> nil
      user -> case type do
        :raw -> user |> Map.delete(:password_hash)
        :struct -> struct(ChenEx.User, user)
      end
    end
  end

  def create(%{id: _, name: name, nickname: _, email: _, password: _, desc: _}=user) do
    case ChenEx.Helper.Riak.exist?("users", name) do
      true -> false
      false ->
        user = user |> Map.put(:password_hash, user.password) |> Map.delete(:password)
        Riak.Object.create(bucket: "users", key: name, data: user) |> Riak.put
        true
    end
  end
end
