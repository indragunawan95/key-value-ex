defmodule KeyValueExWeb.Graphql.KeyValue.KeyValueTest do
  use ExUnit.Case

  @mutation_notation """
  mutation($key: String!, $value: String!) {
    storeKeyValue(key: $key, value: $value) {
      key
      value
    }
  }
  """

  @query_notation """
  query($key: String!) {
    fetchKeyValue(key: $key) {
      key
      value
    }
  }
  """

  describe "store_key_value" do
    test "store_key_value stores a key-value pair successfully" do
      variables = %{"key" => "testKey", "value" => "testValue"}

      res =
        Absinthe.run(@mutation_notation, KeyValueExWeb.Schema, variables: variables, context: %{})

      assert {:ok, %{data: %{"storeKeyValue" => %{"key" => "testKey", "value" => "testValue"}}}} =
               res
    end

    test "attempt to store a key-value pair with an empty key fails" do
      variables = %{"key" => "", "value" => "testValue"}

      res =
        Absinthe.run(@mutation_notation, KeyValueExWeb.Schema, variables: variables, context: %{})

      assert match?({:ok, %{errors: _}}, res)
    end
  end

  describe "fetch_key_value" do
    test "fetch_key_value return a key-value pair successfully" do
      variables = %{"key" => "testKey"}

      res =
        Absinthe.run(@query_notation, KeyValueExWeb.Schema, variables: variables, context: %{})

      assert {:ok, %{data: %{"fetchKeyValue" => %{"key" => "testKey", "value" => "testValue"}}}} =
               res
    end

    test "fetch_key_value return a key-value pair with null value if not found" do
      variables = %{"key" => "testKeyNotFound"}

      res =
        Absinthe.run(@query_notation, KeyValueExWeb.Schema, variables: variables, context: %{})

      assert {:ok, %{data: %{"fetchKeyValue" => %{"key" => "testKeyNotFound", "value" => nil}}}} =
               res
    end

    test "attempt to get a key-value pair with an empty key fails" do
      variables = %{"key" => ""}

      res =
        Absinthe.run(@query_notation, KeyValueExWeb.Schema, variables: variables, context: %{})

      assert match?({:ok, %{errors: _}}, res)
    end
  end
end
