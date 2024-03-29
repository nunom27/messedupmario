{-|
Module      : Tarefa1
Description : Verifica colisões
Copyright   : Nuno Miguel Paiva Fernandes <a107317@alunos.uminho.pt>
              Pedro Herculano Soares Oliveira do Lago Esteves <a106839@alunos.uminho.pt>

Módulo para a realização da Tarefa 1 de LI1 em 2023/24.

IMPORTANTE -> Tudo com IMPORTANTE tem dimensoes do bloco do mapa, possivel alteraçoes
-}
module Tarefa1 where

import LI12324
    ( Personagem(posicao, tamanho),
      Posicao,
      Hitbox,
      Mapa(..),
      Bloco(Porta, Plataforma, Tunel, Alcapao) )
import Graphics.Gloss.Data.Point (pointInBox)
import GHC.Float (double2Float, double2Int, int2Double)
import Graphics.Gloss.Interface.Environment (getScreenSize)
import Utilities

dimensaobloco :: Double
dimensaobloco = 1





-- | caso a personagem esteja fora do mapa a personagem esta a colidir com as paredes externas, || personagens a colidir com as platafromas do mapa

--dimensao de cada bloco é 1x1 por
colisoesParede :: Mapa -> Personagem -> Bool
colisoesParede mapa perso = sobreposicao (genHitbox perso) ((a,b),(c,b-1))
                            || sobreposicao (genHitbox perso) ((a,d),(c,d+1))
                            || sobreposicao (genHitbox perso) ((a-1,b),(a,d))
                            || sobreposicao (genHitbox perso) ((c,b+1),(c,d))
                            || not (all (==False) (map (sobreposicao (genHitbox perso)) (getMapColisions dimensaobloco [Plataforma,Tunel,Alcapao,Porta] (dimensaobloco*0.5,dimensaobloco*0.5) mapa)))
                            where ((a,b),(c,d)) = getMapaDimensoes dimensaobloco mapa



-- Colisoes START - o x em todas as funçoes é o lado do tamanho de um bloco
-- | dimensoes do mapa x e y 
getMapaDimensoes :: Double -> Mapa -> Hitbox
getMapaDimensoes x (Mapa _ _ (h:t)) = ((0,0),(fromIntegral (length (h:t))*x,fromIntegral (length h)*x))

-- |funçao que dá todas as hitbox de Plataformas - IMPORTANDE depende de dimensoes do bloco
getMapColisions :: Double -> [Bloco] -> Posicao -> Mapa -> [Hitbox]
getMapColisions x l _ (Mapa _ _ []) = []
getMapColisions x l (a,b) (Mapa c d (h:t)) = mapablocoshitbox x l (a,b) h ++ getMapColisions x l (a,b+x) (Mapa c d t)



-- | a partir de uma string de blocos retorna uma lista das suas hitbox - IMPORTANTE depende da dimensao do bloco 10x10
mapablocoshitbox :: Double -> [Bloco] -> Posicao -> [Bloco] -> [Hitbox]
mapablocoshitbox x l _ [] = []
mapablocoshitbox x l (a,b) (h:t)    | h `elem` l = mapablocoshitbox x l (a+x,b) t ++ [gethitboxbloco x (a,b)]
                                    | otherwise = mapablocoshitbox x l (a+x,b) t
-- faz a hitbox de casa bloco a partir de uma posiçao - assumindo que a IMPORTANTE dimensao do bloco é 10x10
gethitboxbloco :: Double -> Posicao -> Hitbox
gethitboxbloco x (a,b) = ((a+(x*0.5),b-(x*0.5)),(a-(x*0.5),b+(x*0.5)))
-- Colisoes END


-- | Colisoes personagem com personagem


colisoesPersonagens :: Personagem -> Personagem -> Bool
colisoesPersonagens p1 p2 = sobreposicao (genHitbox p1) (genHitbox p2)



-- Colisoes personagem START
-- | A partir de uma personagem gera a hitbox correspondente
genHitbox :: Personagem -> Hitbox
genHitbox p = (p1,p2)
    where p1 = (xp - fst (tamanho p)/2, yp - snd (tamanho p)/2)
          p2 = (xp + fst (tamanho p)/2, yp + snd (tamanho p)/2)
          xp = fst (posicao p)
          yp = snd (posicao p)

-- | verifica se duas hitboxes estão sobrepostas independentemente do seu tamanho
sobreposicao :: Hitbox -> Hitbox -> Bool
sobreposicao h1 h2= sobreposicaoAux h1 h2 || sobreposicaoAux h2 h1

-- | verifica se duas hitboxes estão sobrepostas (porém só funciona se h2 for menor que h1)
sobreposicaoAux :: Hitbox -> Hitbox -> Bool
sobreposicaoAux ((x1,y1), (x2,y2)) ((x3,y3),(x4,y4)) = pointInBox (double2Float x3,double2Float y3) (double2Float x1,double2Float y1) (double2Float x2,double2Float y2)
                                                    || pointInBox (double2Float x4,double2Float y4) (double2Float x1,double2Float y1) (double2Float x2,double2Float y2)
                                                    || pointInBox (double2Float x3,double2Float y4) (double2Float x1,double2Float y1) (double2Float x2,double2Float y2)
                                                    || pointInBox (double2Float x4,double2Float y3) (double2Float x1,double2Float y1) (double2Float x2,double2Float y2)
-- Colisoes personagem END                                                

getcenterofhitbox :: Double -> [Hitbox] -> [Posicao]
getcenterofhitbox escala l = foldl (\x y -> (fst(fst y)-(escala*0.5),snd(fst y)+(escala*0.5)):x) [] l
