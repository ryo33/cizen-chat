alias Cizen.Effects.{Start, Receive, Subscribe, Dispatch}
alias Cizen.EventFilter
alias CizenChat.Events.{Lounge, Room}
alias CizenChat.Automata

defmodule CizenChat.Automata.Lounge do
  use Cizen.Automaton

  defstruct []

  @impl true
  def spawn(id, _) do
    perform id, %Subscribe{
      event_filter: EventFilter.new(
        event_type: Lounge.Join
      )
    }

    perform id, %Subscribe{
      event_filter: EventFilter.new(
        event_type: Room.Create.Done
      )
    }

    %{
      avatars: [] # list of avatar IDs
    }
  end

  @impl true
  def yield(id, state) do
    IO.puts("Lounge: avatars=#{Enum.join(state.avatars, ", ")}")

    event = perform id, %Receive{}
    case event.body do
      %Lounge.Join{} ->
        avatar_id = perform id, %Start{saga: %Automata.Avatar{}}

        IO.puts("Lounge <= Lounge.Join: avatar_id=#{avatar_id}")
        perform id, %Dispatch{
          body: %Lounge.Join.Welcome{
            join_id: event.id,
            avatar_id: avatar_id
          }
        }

        %{avatars: [avatar_id | state.avatars]}
      %Room.Create.Done{create_id: _create_id, room_id: _room_id} ->
        IO.puts("Lounge <= Room.Create.Done")
        %{avatars: state.avatars}
    end
  end
end
