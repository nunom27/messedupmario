module Utilities where
import Graphics.Gloss
import LI12324

type Images = [(Theme, [(String,Picture)])]

type Levels = [(Jogo, Bool)]

data State = State {
    levels      :: Levels,
    initLevel   :: Jogo,
    currentLevel:: Int,
    menuState :: MenuState,
    currentMenu :: Menu,
    time  :: Float,
    options :: Options,
    exitGame  :: Bool,
    images:: Images,
    animTime  :: Float,
    editorState      :: EditorState,
    cheats          :: Bool,
    screenSize      :: (Int, Int)
}

data Options = Options {
    currentTheme :: Theme
}

data EditorState = EditorState {
    tempGame        :: Jogo,
    levelEditorPos  :: Posicao,
    selectFunc      :: Int,
    removingEnemies :: Bool,
    savingGame      :: Bool
}

data MenuState = MenuState {
    selectedButton :: Int,
    pressingButton :: Bool
}

data Theme = Default | Minecraft deriving (Eq)
data Menu = InGame | MainMenu | OptionsMenu | LevelSelection | LevelEditor | GameOver deriving (Eq)

-- Constante referente à velocidade que as personagens se movem nas escadas
ladderSpeed :: Double
ladderSpeed = 2.4

-- | Função que substitui o valor de um determinado indíce de uma lista
replace :: [a] -> (Int, a) -> [a]
replace xs (i, e) = before ++ [e] ++ after
  where
    (before, _:after) = splitAt i xs

-- | Função que substitui o valor de um determinado indíce de uma matriz
replaceMat :: [[a]] -> (Int, Int, a) -> [[a]]
replaceMat mat (x,y,a) = replace mat (y,replace (mat !! y) (x, a))

replaceMapGame :: Posicao -> Bloco -> Jogo -> Jogo
replaceMapGame (x,y) bloco jog = jog {
    mapa = (Mapa a b mat')
}
    where (Mapa a b mat) = mapa jog
          mat' = replaceMat mat (floor x,floor y,bloco)

-- | Retorna as posições de todos os blocos de um certo tipo numa matriz
getPosOfBlock :: Bloco -> [[Bloco]] -> [Posicao]
getPosOfBlock bloco mat = [(x,y) | x <- [0..fromIntegral (length (head mat)-1)], y <- [0..fromIntegral (length mat)-1], mat !! round y !! round x == bloco]

-- | Retorna as posições de todos os blocos de um certo tipo num dado mapa
getPosOfBlockMap :: Bloco -> Mapa -> [Posicao]
getPosOfBlockMap bloco (Mapa _ _ blocos) = getPosOfBlock bloco blocos

mapToFile :: Mapa -> String
mapToFile (Mapa pi pf blocos) = "Mapa " ++ show pi ++ " " ++ show pf ++ "\n" ++ concat (map (\l -> show l ++ ",\n") blocos)