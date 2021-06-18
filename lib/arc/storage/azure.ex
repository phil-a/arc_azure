defmodule Arc.Storage.Azure do
  @moduledoc """
  This module provides an Arc storage adapter for Azure Storage
  """

  @doc """
  Puts the file in Azure Storage Container

  Returns `{:ok, file.file_name}` if upload successful or `{:error, conn}` if upload fails.

  ## Examples

      iex> Arc.Storage.Azure.put(YourApp.Uploaders.Image, :thumbnail, {%{file_name: "Sample.png"}, "4958"})
      {:ok, _conn} -> {:ok, file.file_name}

  """
  def put(definition, version, {file, scope}) do
    destination_dir = definition.storage_dir(version, {file, scope})

    options = get_options(definition, version, {file, scope})

    case upload_file(destination_dir, file, options) do
      {:ok, _conn} -> {:ok, file.file_name}
      {:error, conn} -> {:error, conn}
    end
  end

  @doc """
  Builds path of the uploaded object.

  Returns the path (as a string) to the uploaded object.

  ## Examples

      iex> Arc.Storage.Azure.url(YourApp.Uploaders.Image, :thumbnail, {%{file_name: "Sample.png"}, "4958"})
      "https://<your-azure-storage-container>.blob.core.windows.net/<destination-dir>/<filename>.<ext>"
      "https://samplestoragecontainer.blob.core.windows.net/uploads/dev/images/4958/Sample.png"

  """
  def url(definition, version, file_and_scope, options \\ []) do
    temp_url_expires_after = Keyword.get(options, :temp_url_expires_after, default_tempurl_ttl())
    temp_url_filename = Keyword.get(options, :temp_url_filename, :false)
    temp_url_inline = Keyword.get(options, :temp_url_inline, :true)
    temp_url_method = Keyword.get(options, :temp_url_method, "GET")
    options =
    Keyword.delete(options, :signed)
    |> Keyword.merge([
      temp_url_expires_after: temp_url_expires_after,
      temp_url_filename: temp_url_filename,
      temp_url_inline: temp_url_inline,
      temp_url_method: temp_url_method
      ]
    )
    build_url(definition, version, file_and_scope, options)
  end

  @doc """
  Deletes the object from the server

  Returns :ok

  ## Examples

      iex> Arc.Storage.Azure.delete(YourApp.Uploaders.Image, :thumbnail, {%{file_name: "Sample.png"}, "4958"})
      :ok

  """
  def delete(_definition, _version, {file, :nil}) do
    server_object = parse_objectname_from_url(file.file_name)
    ExAzure.request!(:delete_blob, [container(), server_object])
    :ok
  end
  def delete(definition, version, {file, scope}) do
    server_object = build_path(definition, version, {file, scope})
    ExAzure.request!(:delete_blob, [container(), server_object])
    :ok
  end

  def default_tempurl_ttl() do
    Application.get_env(:arc, :default_tempurl_ttl, (30 * 24 * 60 * 60))
  end

  #
  # Private
  #
  defp container() do
    Application.get_env(:arc_azure, :container)
  end

  defp host() do
    Application.get_env(:arc_azure, :cdn_url) <> "/" <> container()
  end

  defp build_path(definition, version, file_and_scope) do
    destination_dir = definition.storage_dir(version, file_and_scope)
    filename = Arc.Definition.Versioning.resolve_file_name(definition, version, file_and_scope)
    Path.join([destination_dir, filename])
  end

  defp build_url(definition, version, file_and_scope, _options) do
    Path.join(host(), build_path(definition, version, file_and_scope))
  end

  defp parse_objectname_from_url(url) do
    [_host, server_object] = String.split(url, "#{host()}/")
    server_object
  end

  defp upload_file(destination_dir, file, options \\ []) do
    filename = Path.join(destination_dir, file.file_name)
    ExAzure.request(:put_block_blob, [container(), filename, get_binary_file(file), options])
  end

  defp get_binary_file(%{path: nil} = file), do: file.binary
  defp get_binary_file(%{path: _} = file), do: File.read!(file.path)

  defp get_options(definition, version, {file, scope}) do
    definition.s3_object_headers(version, {file, scope})
    |> ensure_keyword_list()
  end

  defp ensure_keyword_list(list) when is_list(list), do: list
  defp ensure_keyword_list(map) when is_map(map), do: Map.to_list(map)

end