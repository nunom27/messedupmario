module Main where

import Graphics.Gloss
import Graphics.Gloss.Interface.IO.Game
import LI12324
import Tarefa1
import Tarefa3
import Tarefa4
import Mapas
import DrawLevel
import DrawMenu
import GHC.Float (float2Double, double2Float)
import System.Exit (exitSuccess)
import System.Random
import Data.Maybe (fromJust)
import Utilities

window :: Display
window = InWindow
    "Donkeykong"
    sizeWin --(700,700)
    (300,200)

eventHandler :: Event -> State -> IO State
eventHandler (EventKey (SpecialKey KeyEsc) Down _ _) state = exitSuccess
eventHandler (EventKey (Char 'm') Down _ _) state = return $ state {currentMenu = MainMenu}
eventHandler event state
    | currentMenu state == InGame = return state {levels = replace (levels state) ((currentLevel state),(eventHandlerInGame event jogo))}
    | otherwise = eventHandlerInMenu event state
    where jogo = (levels state) !! (currentLevel state)

timeHandler :: Float -> State -> IO State
timeHandler time (State {exitGame = True}) = exitSuccess
timeHandler time state = do generateRandomNumber <- randomRIO (1, 100 :: Int)
                            return $ state {levels = replace (levels state) ((currentLevel state),movimenta generateRandomNumber (float2Double time) jogo)}
    where jogo = (levels state) !! (currentLevel state)

draw :: State -> IO Picture
draw state = do
    putStrLn ("Posicao jog: " ++ (show (posicao $ jogador jogo)))
    putStrLn ("Posicao jog scaled: " ++ (show ((((double2Float $ fst $ posicao $ jogador jogo) * double2Float escalaGloss) - fromIntegral (fst sizeWin)/2), ((-(double2Float $ snd $ posicao $ jogador jogo) * double2Float escalaGloss) + fromIntegral (snd sizeWin)/2))))
    putStrLn ("Not on floor: " ++ show (gravidadeQuedaonoff (mapa (jogo)) (jogador jogo)))
    putStrLn ("Velocidade jogador: " ++ (show (velocidade $ jogador (jogo))))
    putStrLn ("Escada: " ++ show (emEscada $ jogador $ jogo))
    putStrLn ("Pontos jog: " ++ show (pontos $ jogador $ jogo))
    putStrLn ("Vida jog: " ++ show (vida $ jogador $ jogo))
    putStrLn ("Pressing button: " ++ show (pressingButton $ menuState state))

    --putStrLn (show (mapa jogo))
    if (currentMenu state == InGame) then return (drawLevel state)
    else return (drawMenu state)
    where jogo = (levels state) !! (currentLevel state)

bgColor :: Color
bgColor = black

fr :: Int
fr = 60

loadImages :: State -> IO State
loadImages state = do
    -- Start of Default theme
    marioandar <- loadBMP "assets/MarioTexture/Marioandar.bmp"
    mariosaltar <- loadBMP "assets/MarioTexture/Mariosaltar.bmp"
    plataforma <- loadBMP "assets/MarioTexture/Plataforma.bmp"
    escada <- loadBMP "assets/MarioTexture/ladder.bmp"
    alcapao <- loadBMP "assets/MarioTexture/Alcapao.bmp"
    tunel <- loadBMP "assets/MarioTexture/Tunel.bmp"
    inimigo <- loadBMP "assets/MarioTexture/Inimigo.bmp"
    moeda <- loadBMP "assets/MarioTexture/Moeda.bmp"
    martelo <- loadBMP "assets/MarioTexture/Martelo.bmp"
    mariocair <- loadBMP "assets/MarioTexture/Mariocair.bmp"
    -- Start of Minecraft theme
    relva <- loadBMP "assets/MinecraftTexture/relva.bmp"
    moedaminecraft <- loadBMP "assets/MinecraftTexture/Moedaminecraft.bmp"
    steveandar <- loadBMP "assets/MinecraftTexture/Steveandar.bmp"
    stevesaltar <- loadBMP "assets/MinecraftTexture/Stevesaltar.bmp"
    stevecair <- loadBMP "assets/MinecraftTexture/Stevecair.bmp"
    inimigominecraft <- loadBMP "assets/MinecraftTexture/Inimigominecraft.bmp"
    alcapaominecraft <- loadBMP "assets/MinecraftTexture/AlcapaoMinecraft.bmp"
    espadaminecraft <- loadBMP "assets/MinecraftTexture/EspadaMinecraft.bmp"
    botaostart <- loadBMP "assets/Buttons/BotaoStart.bmp"
    botaostartHover <- loadBMP "assets/Buttons/BotaoStartHover.bmp"
    botaostartPressed <- loadBMP "assets/Buttons/BotaoStartPressed.bmp"
    botaoSettings <- loadBMP "assets/Buttons/BotaoSettings.bmp"
    botaoSettingsHover <- loadBMP "assets/Buttons/BotaoSettingsHover.bmp"
    botaoSettingsPressed <- loadBMP "assets/Buttons/BotaoSettingsPressed.bmp"
    menuBanner <- loadBMP "assets/MenuPrototype.bmp"
    botaoQuit <- loadBMP "assets/Buttons/BotaoQuit.bmp"
    botaoQuitHover <- loadBMP "assets/Buttons/BotaoQuitHover.bmp"
    botaoQuitPressed <- loadBMP "assets/Buttons/BotaoQuitPressed.bmp"
    return  state {
        images = [
            (Default,
            [("marioandar", marioandar),
            ("mariosaltar", mariosaltar),
            ("escada", escada),
            ("plataforma", plataforma),
            ("alcapao", alcapao),
            ("tunel", tunel),
            ("inimigo", inimigo),
            ("moeda", moeda),
            ("martelo", martelo),
            ("mariocair", mariocair),
            ("botaostart", botaostart),
            ("botaostartHover", botaostartHover),
            ("botaostartPressed", botaostartPressed),
            ("botaoSettings", botaoSettings),
            ("botaoSettingsHover", botaoSettingsHover),
            ("botaoSettingsPressed", botaoSettingsPressed),
            ("botaoQuit", botaoQuit),
            ("botaoQuitHover", botaoQuitHover),
            ("botaoQuitPressed", botaoQuitPressed),
            ("menuBanner", menuBanner)]),
            (Minecraft,
            [("marioandar", steveandar),
            ("mariosaltar", stevesaltar),
            ("escada", escada),
            ("plataforma", relva),
            ("alcapao", alcapaominecraft),
            ("tunel", tunel),
            ("inimigo", inimigominecraft),
            ("moeda", moedaminecraft),
            ("martelo", espadaminecraft),
            ("mariocair", stevecair),
            ("botaostart", botaostart)])
            ]
        }

updateValueDict :: Eq a => a -> [b] -> b -> [b]
updateValueDict key dict value = dict --map (\(keyD, valueD) -> if key==keyD then (keyD, value) else (keyD, valueD)) dict


main :: IO ()
main = do
    putStrLn (show (fst sizeWin, snd sizeWin))
    initState <- loadImages initialState
    playIO window bgColor fr initState draw eventHandler timeHandler