defmodule BOServer.XMLAnalyser do
  @moduledoc """
  Documentation for BOServer.
  """

  def bo_file_valid?("<actions>" <> xml) do
    xml
    |> String.trim_leading
    |> open_tag_action == "</actions>"
  end

  defp open_tag_action("<action>" <> xml) do
    xml
    |> String.trim_leading
    |> parse_action(%{pop: 1, timer: 1, build: 1})
    |> String.trim_leading
    |> close_tag_action
    |> String.trim_leading
    |> open_tag_action
  end
  defp open_tag_action(xml), do: xml

  defp parse_action("<pop>" <> xml, %{pop: 1, timer: t, build: b})  do
    xml
    |> String.trim_leading
    |> parse_pop
    |> String.trim_leading
    |> close_tag_pop
    |> String.trim_leading
    |> parse_action(%{pop: 0, timer: t, build: b})
  end
  defp parse_action("<timer>" <> xml, %{pop: p, timer: 1, build: b})  do
    xml
    |> String.trim_leading
    |> parse_timer
    |> String.trim_leading
    |> close_tag_timer
    |> String.trim_leading
    |> parse_action(%{pop: p, timer: 0, build: b})
  end
  defp parse_action(xml, _), do: xml

  defp parse_pop(xml) do
    String.replace("@" <> xml, ~r{^@[\d]+}, "", global: false)
  end

  defp parse_timer(xml) do
    String.replace("@" <> xml, ~r{^@[\d]+:[0-5][\d]}, "", global: false)
  end

  defp close_tag_pop("</pop>" <> xml), do: xml
  defp close_tag_pop(_), do: ""

  defp close_tag_timer("</timer>" <> xml), do: xml
  defp close_tag_timer(_), do: ""

  defp close_tag_action("</action>" <> xml), do: xml
  defp close_tag_action(_), do: ""
end
