defmodule Arc.Storage.Azure do
  @moduledoc :false

  def put(definition, version, {file, scope}) do
    destination_dir = definition.storage_dir(version, {file, scope})
    case upload_file(destination_dir, file) do
      {:ok, _conn} -> {:ok, file.file_name}
      {:error, conn} -> {:error, conn}
    end
  end

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

  defp container() do
    Application.get_env(:arc_azure, :container)
  end

  def default_tempurl_ttl() do
    Application.get_env(:arc, :default_tempurl_ttl, (30 * 24 * 60 * 60))
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

  defp upload_file(destination_dir, file) do
    filename = Path.join(destination_dir, file.file_name)
    ExAzure.request(:put_block_blob, [container(), filename, File.read!(file.path)])
  end
end