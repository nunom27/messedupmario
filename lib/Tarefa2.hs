{-|
Module      : Tarefa2
Description : Valida jogo
Copyright   : Nuno Miguel Paiva Fernandes <a107317@alunos.uminho.pt>
              Pedro Herculano Soares Oliveira do Lago Esteves <a106839@alunos.uminho.pt>

Módulo para a realização da Tarefa 2 de LI1 em 2023/24.
-}
module Tarefa2 where

import LI12324
import Tarefa1 (sobreposicao, genHitbox)
import Data.List (elemIndex, elemIndices, groupBy, sortOn)
import Data.Maybe (fromMaybe)
import GHC.Float (double2Int)
import Utilities



-- Test data START

-- Test data END

valida :: Jogo -> Bool
valida jogo = validaChao (mapa jogo) &&
    validaRessalta (jogador jogo) (inimigos jogo) &&
    validaPosJogInim (jogador jogo) (inimigos jogo) &&
    validaNumIniAndVidaFan (inimigos jogo) &&
    validaEscadas (mapa jogo) &&
    validaAlcapoes (mapa jogo) &&
    validaPosPersColecs jogo

-- | Verifica o chao do mapa
validaChao :: Mapa -> Bool
validaChao (Mapa _ _ mapMat) = all (== Plataforma) (last mapMat)

-- | Verifica se o ressalto do jogador é falso e se o ressalto de todos os inimigos é verdadeiro
validaRessalta :: Personagem -> [Personagem] -> Bool
validaRessalta jogador inimigosList = not (ressalta jogador) && all ressalta inimigosList

-- | Verifica a posiçao inicial se sobrepoem ou nao com os inimigos
validaPosJogInim :: Personagem -> [Personagem] -> Bool
validaPosJogInim jogador inimigosList = not (any  (\i -> sobreposicao (genHitbox i) (genHitbox jogador) ) inimigosList)

-- | Verfica se existem pelo menos 2 inimigos e se cada fantasma tem apenas 1 vida
validaNumIniAndVidaFan :: [Personagem] -> Bool
validaNumIniAndVidaFan inis = (length inis >= 2) && (all (\f -> vida f == 1) $ filter (\p -> tipo p == Fantasma || tipo p == EyeEntidade) inis)

-- | Verfica se as escadas são continuas e terminam e começam com plataforma
validaEscadas :: Mapa -> Bool
validaEscadas (Mapa _ _ mat) = all validateEachOne (agrupaEscadas (getPosOfBlock Escada mat))
    where validateEachOne :: [Posicao] -> Bool
          validateEachOne ls = ((x1,y1-1) `elem` getPosOfBlock Plataforma mat &&
                                (x2,y2-1) `elem` getPosOfBlock Escada mat) ||
                                ((x2,y2+1) `elem` getPosOfBlock Plataforma mat &&
                                (x1,y1+1) `elem` getPosOfBlock Escada mat)
            where (x1,y1) = head ls
                  (x2,y2) = last ls

-- | Agrupa as escadas em grupos de 2
agrupaEscadas :: [Posicao] -> [[Posicao]]
agrupaEscadas pos = map (\p-> [head p] ++ [last p]) $ agrupaEscadasAux (groupEscadasAux pos)

agrupaEscadasAux :: [Posicao] -> [[Posicao]]
agrupaEscadasAux [] = []
agrupaEscadasAux [x] = [[x]]
agrupaEscadasAux ((x,y):t)
    | elem (x,y+1) (head r) = ((x,y) : (head r)) : tail r
    | otherwise = [(x,y)] : r
    where r = agrupaEscadasAux t

groupEscadasAux :: [Posicao] -> [Posicao]
groupEscadasAux pos = sortOn fst pos

-- TODO: Discuss the size of blocks and player, needed for the 7th step
-- | Verifica se os alçapões se encontram pelo menos em grupos de 2
validaAlcapoes :: Mapa -> Bool
validaAlcapoes (Mapa _ _ mat) = all (\(x,y) -> (x+1,y) `elem` matEsc || (x-1,y) `elem` matEsc) matEsc
    where matEsc = getPosOfBlock Alcapao mat

-- | Verifica se os colecionaveis se encontram em espaços vazios no mapa e se as personagens se encontram em espaços vazios do mapa
validaPosPersColecs :: Jogo -> Bool
validaPosPersColecs jogo = validaPosPers (jogador jogo) (inimigos jogo) (mapa jogo) && validaColecs (colecionaveis jogo) (mapa jogo)

-- | Verifica se os colecionávei se encontram em espaços vazios do mapa
validaColecs :: [(Colecionavel,Posicao)] -> Mapa -> Bool
validaColecs colecs (Mapa _ _ mat)
    | null colecs = True
    | otherwise = all (\(c,(x,y)) -> (fromIntegral $ floor x, fromIntegral $ floor y) `elem` getPosOfBlock Vazio mat) colecs || all (\(c,(x,y)) -> (fromIntegral $ floor x, fromIntegral $ floor y) `elem` getPosOfBlock Escada mat) colecs

-- | Verifica se as personagens (jogador e inimigos) se encontram em espaços vazios do mapa
validaPosPers :: Personagem -> [Personagem] -> Mapa -> Bool
validaPosPers player inms (Mapa (pos, dir) _ mat) = (floorPos pos `elem` getPosOfBlock Vazio mat) || (floorPos pos `elem` getPosOfBlock Escada mat) && all (\inm -> if tipo inm /= Barril then floorPos (posicao inm) `elem` getPosOfBlock Vazio mat else True) inms

floorPos :: Posicao -> Posicao
floorPos (x,y) = (fromIntegral $ floor x, fromIntegral $ floor y)