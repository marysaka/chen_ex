defmodule ChenEx.Helper.Riak do

  def get(bucket, key) do
    case Riak.find(bucket, key) do
      nil -> nil
      res -> case res.content_type do
        'application/x-erlang-binary' -> res.data |> :erlang.binary_to_term
        _ -> res
      end
    end
  end

  def exist?(bucket, key), do: get(bucket, key) != nil

  def put(bucket, key, data) do
    Riak.Object.create(bucket: bucket, key: key, data: data) |> Riak.put
  end
end
