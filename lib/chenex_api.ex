defmodule ChenEx.API.HTTP do
  use Ewebmachine.Builder.Resources
  resources_plugs nomatch_404: true

  resource "/api/v1/user/:name" do %{name: name} after
    plug ChenEx.API.Common

    resource_exists do
      user=ChenEx.User.get(state.name)
      pass(user !== nil, json_obj: user)
    end
  end
end

