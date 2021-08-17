defmodule QueryBuilder.Extension do
  @moduledoc ~S"""
  Use this module to create an extension module to `QueryBuilder` for app specific query utilities.
  Use your query builder extension module wherever you would normally use `QueryBuilder`

  Example:
  ```
  defmodule MyApp.QueryBuilder do
    use QueryBuilder.Extension

    defmacro __using__(opts) do
      quote do
        require QueryBuilder
        QueryBuilder.__using__(unquote(opts))
      end
    end

    # Add app specific query functions
    #---------------------------------

    def search(query, field, search_term) do
      # Implement custom search query here
      # For example see https://gist.github.com/onomated/36e23eb2fb80669b7e440af2a450ea7f
    end
  end

  defmodule MyApp.Accounts.User do
    use MyApp.QueryBuilder

    schema "users" do
      field :name, :string
      field :active, :boolean
    end
  end

  defmodule MyApp.Accounts do
    alias MyApp.QueryBuilder, as: QB

    def list_schemas(opts \\ []) do
      # Query list can include custom search implementation as well as:
      # [search: {"users", "john doe"}}, where: {active: true}]
      MyApp.Accounts.User
      |> QB.from_list(opts)
      |> Repo.all()
    end
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      # Expose all QueryBuilder functions: QueryBuilder.__info__(:functions)

      defdelegate left_join(query, assoc_fields, filters \\ [], or_filters \\ []),
        to: QueryBuilder

      defdelegate maybe_where(query, bool, filters), to: QueryBuilder

      defdelegate maybe_where(query, condition, fields, filters, or_filters \\ []),
        to: QueryBuilder

      defdelegate new(ecto_query), to: QueryBuilder
      defdelegate order_by(query, value), to: QueryBuilder
      defdelegate order_by(query, assoc_fields, value), to: QueryBuilder
      defdelegate preload(query, assoc_fields), to: QueryBuilder
      defdelegate where(query, filters), to: QueryBuilder
      defdelegate where(query, assoc_fields, filters, or_filters \\ []), to: QueryBuilder

      @doc ~S"""
      Allows to pass a list of operations through a keyword list.

      Example:
      ```
      QueryBuilder.from_list(query, [
        where: [name: "John", city: "Anytown"],
        preload: [articles: :comments]
      ])
      ```
      """
      def from_list(query, nil), do: query
      def from_list(query, []), do: query

      def from_list(query, [{operation, arguments} | tail]) do
        arguments =
          cond do
            is_tuple(arguments) -> Tuple.to_list(arguments)
            is_list(arguments) -> [arguments]
            true -> List.wrap(arguments)
          end

        apply(__MODULE__, operation, [query | arguments])
        |> from_list(tail)
      end
    end
  end
end
