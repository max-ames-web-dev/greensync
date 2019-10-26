defmodule Greenhousex.Harvest do
  use Tesla

  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.BaseUrl, "https://harvest.greenhouse.io/v1")

  plug(Tesla.Middleware.BasicAuth, %{
    username: Application.get_env(:greensync, :greenhouse_api_token),
    password: ""
  })

  plug(Tesla.Middleware.Retry,
    delay: 10000,
    max_retries: 5,
    max_delay: 10000,
    should_retry: fn
      {:ok, %{status: status}} when status in [429, 500] -> true
      {:ok, _} -> false
      {:error, _} -> true
    end
  )

  alias Greenhousex.Harvest.{Candidate, Scorecard, User}

  def get_users(query \\ []) do
    "/users"
    |> stream_get(query: query)
    |> Stream.map(&parse_users/1)
  end

  defp parse_users({:ok, %{status: 200, body: users}}) do
    {:ok, Enum.map(users, &User.from_map/1)}
  end

  defp parse_users({_, %{body: body}}), do: {:error, body}

  def get_candidates(query \\ []) do
    "/candidates"
    |> stream_get(query: query)
    |> Stream.map(&parse_candidates/1)
  end

  defp parse_candidates({:ok, %{status: 200, body: candidates}}) do
    {:ok, Enum.map(candidates, &Candidate.from_map/1)}
  end

  defp parse_candidates({_, %{body: body}}), do: {:error, body}

  def get_scorecards(query \\ []) do
    "/scorecards"
    |> stream_get(query: query)
    |> Stream.map(&parse_scorecards/1)
  end

  defp parse_scorecards({:ok, %{status: 200, body: scorecards}}) do
    {:ok, Enum.map(scorecards, &Scorecard.from_map/1)}
  end

  defp parse_scorecards({_, %{body: body}}), do: {:error, body}

  def get_applications(query \\ []) do
    "/applications"
    |> stream_get(query: query)
    |> Stream.map(&parse_applications/1)
  end

  defp parse_applications({:ok, %{status: 200, body: applications}}) do
    {:ok, Enum.map(applications, &Greenhousex.Harvest.Application.from_map/1)}
  end

  defp parse_applications({_, %{body: body}}), do: {:error, body}

  def get_jobs(query \\ []) do
    "/jobs"
    |> stream_get(query: query)
    |> Stream.map(&parse_jobs/1)
  end

  defp parse_jobs({:ok, %{status: 200, body: jobs}}) do
    {:ok, Enum.map(jobs, &Greenhousex.Harvest.Job.from_map/1)}
  end

  defp parse_jobs({_, %{body: body}}), do: {:error, body}

  def get_job_stages(query \\ []) do
    "/job_stages"
    |> stream_get(query: query)
    |> Stream.map(&parse_job_stages/1)
  end

  defp parse_job_stages({:ok, %{status: 200, body: job_stages}}) do
    {:ok, Enum.map(job_stages, &Greenhousex.Harvest.JobStage.from_map/1)}
  end

  defp parse_job_stages({_, %{body: body}}), do: {:error, body}

  def get_offices(query \\ []) do
    "/offices"
    |> stream_get(query: query)
    |> Stream.map(&parse_offices/1)
  end

  defp parse_offices({:ok, %{status: 200, body: offices}}) do
    {:ok, Enum.map(offices, &Greenhousex.Harvest.Office.from_map/1)}
  end

  defp parse_offices({_, %{body: body}}), do: {:error, body}

  def get_departments(query \\ []) do
    "/departments"
    |> stream_get(query: query)
    |> Stream.map(&parse_departments/1)
  end

  defp parse_departments({:ok, %{status: 200, body: departments}}) do
    {:ok, Enum.map(departments, &Greenhousex.Harvest.Department.from_map/1)}
  end

  defp parse_departments({_, %{body: body}}), do: {:error, body}

  defp stream_get(url, opts) do
    Stream.resource(
      fn ->
        query = Keyword.get(opts, :query, [])
        Keyword.get(query, :page, 1)
      end,
      fn
        nil ->
          {:halt, nil}

        page ->
          query = Keyword.get(opts, :query, [])
          new_query = Keyword.put(query, :page, page)
          new_opts = Keyword.put(opts, :query, new_query)

          {_, response} = result = get(url, new_opts)
          link_header = Tesla.get_header(response, "link")

          if has_next?(link_header) do
            {[result], page + 1}
          else
            {[result], nil}
          end
      end,
      fn a -> a end
    )
  end

  defp has_next?(link_header) when is_binary(link_header) do
    Regex.match?(~r/<([^>]+)>; rel="next"/, link_header)
  end

  defp has_next?(_), do: false
end