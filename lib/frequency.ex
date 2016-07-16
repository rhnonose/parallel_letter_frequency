defmodule Frequency do
	use Application
  @doc """
  Count letter frequency in parallel.

  Returns a dict of characters to frequencies.

  The number of worker processes to use can be set with 'workers'.
  """
  def frequency([], _) do
  	%{}
  end

  @spec frequency([String.t], pos_integer) :: map
  def frequency(texts, workers) do
  	texts
  	|> Enum.join
  	|> filter_letters
  	|> count_frequency(workers)
  end


  def filter_letters(text) do
  	text
  	|> String.downcase
  	|> String.codepoints
  	|> Enum.filter(fn letter -> !Enum.member?(
  		[" ", ",", ".", "?", "!", "'", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
        letter) end)
  end

  def count_frequency(text, workers) do
  	1..workers
  	|> Enum.map(fn _ -> spawn(__MODULE__, :count_letter, [self]) end)
  	|> schedule_processes(text, Enum.uniq(text), %{})
  end

  def schedule_processes(processes, text, letters, result_map) do
  	receive do
  		{:ready, pid} when length(letters) > 0 ->
  			[h | t] = letters
  			send pid, {:count, text, h, self}
  			schedule_processes(processes, text, t, result_map)
  		{:ready, pid} ->
  			send pid, {:end}
  			if length(processes) > 1 do
  				rest = List.delete(processes, pid)
  				schedule_processes(rest, text, letters, result_map)
  			else
  				result_map	
  			end
  		{:freq, count, letter} ->
  			schedule_processes(processes, text, letters, Enum.into(result_map, %{letter => count}))
  	end
  end

  def count_letter(squeduler) do
  	send squeduler, {:ready, self}
  	receive do
  		{:count, text, letter, resp} ->
  			send resp, {:freq, Enum.count(text, fn n -> n == letter end), letter}
  			count_letter(resp)
  		{:end} -> exit(:normal)
  	end
  end


end
