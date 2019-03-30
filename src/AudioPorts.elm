port module AudioPorts exposing
    ( ScheduleNoteArguments
    , audioClockUpdate
    , scheduleNote
    , startAudioClock
    , stopAudioClock
    )


type alias ScheduleNoteArguments =
    { time : Float
    , freqValue : Float
    , noteDuration : Float
    }


port startAudioClock : () -> Cmd msg


port stopAudioClock : () -> Cmd msg


port audioClockUpdate : (Float -> msg) -> Sub msg


port scheduleNote : ScheduleNoteArguments -> Cmd msg
