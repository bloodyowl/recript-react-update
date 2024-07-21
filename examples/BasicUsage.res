module ReactUpdate = {
  type action = Tick | Reset
  type state = {elapsed: int}
  @react.component
  let make = () => {
    let (state, send) = ReactUpdate.useReducerWithMapState(
      (state, action) =>
        switch action {
        | Tick =>
          UpdateWithSideEffects(
            {elapsed: state.elapsed + 1},
            ({send}) => {
              let timeoutId = Js.Global.setTimeout(() => send(Tick), 1_000)
              Js.Console.log2("schedule next tick: ", timeoutId)
              Some(() => {
                Js.Console.log2("cleanup: ", timeoutId)
                Js.Global.clearTimeout(timeoutId)
              })
            },
          )
        | Reset => Update({elapsed: 0})
        },
      () => {elapsed: 0},
    )
    React.useEffect0(() => {
      send(Tick)
      None
    })
    <div>
      {state.elapsed->Js.String.make->React.string}
      <button onClick={_ => send(Reset)}> {"Reset"->React.string} </button>
    </div>
  }
}

module ReactRestate = {
  type action = Tick | Reset
  type state = {elapsed: int}
  type deferredAction = ScheduleNextTick
  module DeferredAction: Restate.HasDeferredAction with type t = deferredAction = {
      type t = deferredAction
      let variantId = action =>
        switch action {
        | ScheduleNextTick => "ScheduleNextTick"
      }
    }
  module RestateReducer = Restate.MakeReducer(DeferredAction)
  let reducer = (state, action) =>
    switch action {
    | Tick =>
      RestateReducer.UpdateWithDeferred(
        {elapsed: state.elapsed + 1},
        ScheduleNextTick
      )
    | Reset => RestateReducer.Update({elapsed: 0})
    }
  let scheduler: (RestateReducer.self<state, action>, deferredAction) => option<unit=>unit> = 
    (self, action) =>
        switch action {
        | ScheduleNextTick =>
          let timeoutId = Js.Global.setTimeout(() => self.send(Tick), 1_000)
          Js.Console.log2("schedule next tick: ", timeoutId)
          Some(() => {
            Js.Console.log2("cleanup: ", timeoutId)
            Js.Global.clearTimeout(timeoutId)
          })
        }
  @react.component
  let make = () => {
    let (state, send, _defer) = RestateReducer.useReducerWithMapState(reducer, scheduler, () => {elapsed: 0})
    React.useEffect0(() => {
      send(Tick)
      None
    })
    <div>
      {state.elapsed->Js.String.make->React.string}
      <button onClick={_ => send(Reset)}> {"Reset"->React.string} </button>
    </div>
  }
}
