module Main exposing (Model, Msg(..), init, main, update, view)

import AudioPorts
import Browser
import Html exposing (Html, button, div, h1, img, input, text)
import Html.Attributes exposing (max, min, src, type_, value)
import Html.Events exposing (on, onClick)
import Html.Events.Extra exposing (targetValueIntParse)
import Json.Decode as Json
import Maybe exposing (withDefault)



---- MODEL ----


noteDuration : Float
noteDuration =
    0.1


subDivision : Float
subDivision =
    1.0


schedulerInterval : Float
schedulerInterval =
    25


freqValue : Float
freqValue =
    440.0


type alias Flags =
    { currentTime : Float }


type alias Model =
    { bpm : Int
    , tickCount : Int
    , nextNoteTime : Float
    , started : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { bpm = 120
      , tickCount = 0
      , nextNoteTime = flags.currentTime
      , started = False
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = ChangeBPM Int
    | AudioClockUpdated Float
    | ToggleMetronome
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeBPM bpm ->
            ( { model | bpm = bpm }, Cmd.none )

        AudioClockUpdated currentTime ->
            let
                nextNoteTime =
                    model.nextNoteTime + (subDivision * (60.0 / toFloat model.bpm))

                note =
                    { time = nextNoteTime
                    , freqValue = freqValue
                    , noteDuration = noteDuration
                    }

                shouldScheduleNextNote =
                    nextNoteTime < (currentTime + noteDuration)
            in
            case shouldScheduleNextNote of
                True ->
                    ( { model | nextNoteTime = nextNoteTime }, AudioPorts.scheduleNote note )

                False ->
                    ( model, Cmd.none )

        ToggleMetronome ->
            let
                cmd =
                    case model.started of
                        True ->
                            AudioPorts.stopAudioClock ()

                        False ->
                            AudioPorts.startAudioClock ()
            in
            ( { model | started = not model.started }, cmd )

        _ ->
            ( model, Cmd.none )



--- SUBSCRIPTIONS ---


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.started then
        AudioPorts.audioClockUpdate AudioClockUpdated

    else
        Sub.none



---- VIEW ----


onInput onChangeAction =
    on "input" <| Json.map onChangeAction targetValueIntParse


renderToggleButton : Model -> Html Msg
renderToggleButton model =
    let
        buttonText =
            case model.started of
                True ->
                    "Stop"

                False ->
                    "Start"
    in
    button [ onClick ToggleMetronome ] [ text buttonText ]


view : Model -> Html Msg
view model =
    div []
        [ text (String.fromInt model.bpm)
        , input
            [ type_ "range"
            , min "10"
            , max "400"
            , value (String.fromInt model.bpm)
            , onInput ChangeBPM
            ]
            []
        , renderToggleButton model
        ]



---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
