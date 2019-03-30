module Main exposing (Model, Msg(..), init, main, update, view)

import AudioPorts
import Browser
import Html exposing (Html, button, div, h1, img, input, text)
import Html.Attributes exposing (class, classList, max, min, src, type_, value)
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


beatCount : Int
beatCount =
    7


schedulerInterval : Float
schedulerInterval =
    25


type alias Flags =
    { currentTime : Float }


type alias Model =
    { bpm : Int
    , currentAudioClockTime : Float
    , currentBeat : Int
    , nextNoteTime : Float
    , started : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { bpm = 120
      , currentAudioClockTime = flags.currentTime
      , currentBeat = 0
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

                freqValue =
                    if currentBeat == 1 then
                        440.0

                    else
                        380.0

                note =
                    { time = nextNoteTime
                    , freqValue = freqValue
                    , noteDuration = noteDuration
                    }

                shouldScheduleNextNote =
                    nextNoteTime < (currentTime + noteDuration)

                currentBeat =
                    if model.currentBeat == beatCount then
                        1

                    else
                        model.currentBeat + 1
            in
            case shouldScheduleNextNote of
                True ->
                    ( { model
                        | nextNoteTime = nextNoteTime
                        , currentBeat = currentBeat
                        , currentAudioClockTime = currentTime
                      }
                    , AudioPorts.scheduleNote note
                    )

                False ->
                    ( { model | currentAudioClockTime = currentTime }, Cmd.none )

        ToggleMetronome ->
            let
                cmd =
                    case model.started of
                        True ->
                            AudioPorts.stopAudioClock ()

                        False ->
                            AudioPorts.startAudioClock ()
            in
            ( { model
                | started = not model.started
                , currentBeat = 0
                , nextNoteTime = model.currentAudioClockTime
              }
            , cmd
            )

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


renderBeats : Model -> Html Msg
renderBeats model =
    let
        renderBeat beatNum =
            div [ classList [ ( "active", beatNum == model.currentBeat ) ] ]
                [ text (String.fromInt beatNum)
                ]

        beats =
            List.range 1 beatCount
                |> List.map renderBeat
    in
    div [ class "beats" ] beats


view : Model -> Html Msg
view model =
    div [ class "main-container" ]
        [ div [ class "controls" ]
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
        , renderBeats model
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
