defmodule Greenhousex.Harvest.Job do
  use TypedStruct

  typedstruct do
    field(:id, integer, enforce: true)
    field(:name, enforce: true)
    field(:confidential, bool, enforce: true)
    field(:status, String.t(), enforce: true)
    field(:department_ids, [integer], enforce: true)
    field(:office_ids, [integer], enforce: true)
    field(:opened_at, DateTime.t())
    field(:created_at, DateTime.t(), enforce: true)
    field(:updated_at, DateTime.t(), enforce: true)
    field(:closed_at, DateTime.t())
  end

  @spec from_map(map()) :: __MODULE__.t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      name: map["name"],
      confidential: map["confidential"],
      status: map["status"],
      department_ids: map["departments"] |> Enum.map(& &1["id"]),
      office_ids: map["offices"] |> Enum.map(& &1["id"]),
      opened_at: to_date(map["opened_at"]),
      created_at: to_date(map["created_at"]),
      updated_at: to_date(map["updated_at"]),
      closed_at: to_date(map["closed_at"])
    }
  end

  defp to_date(nil), do: nil

  defp to_date(value) do
    with {:ok, datetime, _offset} <- DateTime.from_iso8601(value) do
      DateTime.truncate(datetime, :second)
    else
      _error -> nil
    end
  end
end
