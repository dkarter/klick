module Main exposing (Model, Msg(..), init, main, update, view)

import AudioPorts
import Browser
import Html exposing (Html, button, div, header, img, span, text)
import Html.Attributes exposing (alt, class, classList, src)
import Html.Events exposing (onClick)



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
    | IncreaseBPM
    | DecreaseBPM
    | AudioClockUpdated Float
    | ToggleMetronome
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        IncreaseBPM ->
            ( { model | bpm = model.bpm + 1 }, Cmd.none )

        DecreaseBPM ->
            ( { model | bpm = model.bpm - 1 }, Cmd.none )

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
            if shouldScheduleNextNote then
                ( { model
                    | nextNoteTime = nextNoteTime
                    , currentBeat = currentBeat
                    , currentAudioClockTime = currentTime
                  }
                , AudioPorts.scheduleNote note
                )

            else
                ( { model | currentAudioClockTime = currentTime }, Cmd.none )

        ToggleMetronome ->
            let
                cmd =
                    if model.started then
                        AudioPorts.stopAudioClock ()

                    else
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


renderToggleButton : Model -> Html Msg
renderToggleButton model =
    let
        buttonText =
            if model.started then
                "Stop"

            else
                "Start"
    in
    button [ onClick ToggleMetronome, alt buttonText, class "play-stop-button" ]
        [ img [ src "play-button.svg" ] []
        ]


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


renderBPM : Model -> Html Msg
renderBPM model =
    div [ class "bpm" ]
        [ span [] [ text (String.fromInt model.bpm) ]
        , span [] [ text "bpm" ]
        ]


renderBPMControls : Model -> Html Msg
renderBPMControls model =
    div [ class "bpm-controls" ]
        [ button [ onClick DecreaseBPM ] [ text "-" ]
        , renderBPM model
        , button [ onClick IncreaseBPM ] [ text "+" ]
        ]


renderControls : Model -> Html Msg
renderControls model =
    div [ class "controls-container" ]
        [ renderBPMControls model
        , renderToggleButton model
        ]


view : Model -> Html Msg
view model =
    div [ class "main-container" ]
        [ header [] [ img [ src "logo.svg" ] [] ]
        , renderBeats model
        , renderControls model
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
