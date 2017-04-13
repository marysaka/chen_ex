defmodule ChenEx.WebFinger do
  defmodule API do
    use Ewebmachine.Builder.Resources
    resources_plugs nomatch_404: true
    resource "/.well-known/host-meta" do %{} after
      plug ChenEx.API.Common
      content_types_provided do: ['application/xrd+xml': :to_xrd]
      defh to_xrd do
        ChenEx.WebFinger.Util.generate_host_meta
      end
    end

    resource "/.well-known/webfinger" do %{} after
      plug ChenEx.API.Common
      plug :fetch_query_params
      content_types_provided do: ['application/xrd+xml': :to_xrd, 'application/jrd+json': :to_json]

      resource_exists do
        data = ChenEx.WebFinger.Util.generate_webfinger_response(conn.params["resource"], :xrd)
        pass(data !== nil, res: data)
      end
      defh to_xrd, do: XmlBuilder.generate(state[:res])
      defh to_json, do: Poison.encode!(state[:res])
    end
  end

  defmodule Util do
    import XmlBuilder

    @users %{"thog" => %{"id" => 1, "username" => "thog"}}

    def search_user(query) do
      ChenEx.User.get(query |> String.split("@#{Application.get_env(:chen_ex, :domain)}") |> Enum.at(0))
    end

    def generate_host_meta do
      base_url = Application.get_env(:chen_ex, :base_url)
      [
        :_doc_type | [element("XRD", %{xmlns: "http://docs.oasis-open.org/ns/xri/xrd-1.0"},
                      [
                        element("Link", %{ref: "lrdd", type: "application/xrd+xml", template: "#{base_url}/.well-known/webfinger?resource={uri}"})
                      ])]
      ] |> generate
    end

    def user_to_webfinger(user) do
      base_url = Application.get_env(:chen_ex, :base_url)
      %{
        "subject" => "acct:" <> user.name <> "@" <> Application.get_env(:chen_ex, :domain),
        "aliases" => ["#{base_url}/user/#{Map.get(user, :id)}", "#{base_url}/@#{Map.get(user, :name)}"],
        "links" => [%{"rel" => "http://schemas.google.com/g/2010#updates-from", "href" => "#{base_url}/users/#{Map.get(user, :name)}.atom"}, %{"rel" => "salmon", "href" => "#{base_url}/api/salmon/#{Map.get(user, :id)}"}]
      }
    end

    def encode_xrd(data) do
      aliases = data["aliases"] |> Enum.map(fn (o) -> element("Alias", o) end)
      links = data["links"] |> Enum.map(fn (o) ->
        data = o["data"]
        element("Link", o |> Map.delete("data"), data)
      end)
      [:_doc_type | [element("XRD", %{xmlns: "http://docs.oasis-open.org/ns/xri/xrd-1.0"},
       [
         element("Subject", data["subject"])
       ] ++ aliases ++ links)]]
    end

    def encode_webfinger_res(res, :xrd) do
      case res do
        nil -> nil
        res -> res |> user_to_webfinger |> encode_xrd
      end
    end

    def encode_webfinger_res(res, :jrd) do
      case res do
        nil -> nil
        res -> res |> user_to_webfinger
      end
    end

    def generate_webfinger_response(request, type) do
      case request do
        nil -> nil
        "acct:" <> query -> encode_webfinger_res(search_user(query), type)
        _ -> nil
      end
    end
  end

end
