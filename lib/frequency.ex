defmodule Frequency do
	use Application
  @doc """
  Count letter frequency in parallel.

  Returns a dict of characters to frequencies.

  The number of worker processes to use can be set with 'workers'.
  """
  @spec frequency([String.t], pos_integer) :: map
  def frequency(texts, _workers) do
  	texts
  	|> Enum.join
  	|> filter_letters
  end

  def filter_letters(text) do
  	text
  	|> String.downcase
  	|> String.codepoints
  	|> Enum.filter(fn letter -> !Enum.member?(
  		[" ", ",", ".", "?", "!", "'"],
        letter) end)
  end

  def count_letter(squeduler) do
  	send squeduler, {:ready, self}
  	receive do
  		{:count, text, letter, resp} ->
  			count = text
  			|> String.codepoints
  			|> Enum.count(fn n -> n == letter end)
  			send resp, {:freq, count}
  		{:end} -> exit(:normal)
  	end
  end


end
