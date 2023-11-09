defmodule EventLog.S3Upload do
  def upload_data(data, extension) do
    sha1 = _generate_filename(data, extension)
    _upload(data, "2trde-images", sha1)
    sha1
  end

  def _generate_filename(data, extension) do
    sha1 = :crypto.hash(:sha, data) |> Base.encode16() |> String.downcase()
    "#{sha1}.#{extension}"
  end

  def _upload(data, bucket, filename) do
    tmp_file = "/tmp/upload_#{:erlang.system_time()}"
    File.write!(tmp_file, data)

    %{status_code: 200} =
      ExAws.S3.Upload.stream_file(tmp_file)
      |> ExAws.S3.upload(bucket, filename, [acl: :public_read, timeout: 600_000, content_type: MIME.from_path(filename)])
      |> ExAws.request!()

    File.rm(tmp_file)
    filename
  end
end
