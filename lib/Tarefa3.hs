{-|
Module      : Tarefa3
Description : Movimenta personagens no jogo
Copyright   : Nuno Miguel Paiva Fernandes <a107317@alunos.uminho.pt>
              Pedro Herculano Soares Oliveira do Lago Esteves <a106839@alunos.uminho.pt>

Módulo para a realização da Tarefa 3 de LI1 em 2023/24.
-}
module Tarefa3 where

import LI12324
import Tarefa1
import Tarefa2
import GHC.Float (float2Double)
import Utilities


movimenta :: Semente -> Tempo -> Jogo -> Jogo
movimenta seed dtime jog = movimentoMacacoMalvado dtime $ portasFuncao $ checkEscadas (acionarAlcapao (removerjogChao ( coletarObjetos dtime (perdeVidaJogadorEnd (hitboxDanoJogadorFinal (inimigoMortoEnd (movimentoInimigos seed (gravidadeQuedaEnd dtime jog))))))))


distancia :: Posicao -> Posicao -> Double
distancia (x,y) (a,b) = sqrt (abs ((x-a)^2+(y-b)^2))



--Dano Jogador START
hitboxDanoJogadorFinal :: Jogo -> Jogo
hitboxDanoJogadorFinal jogo = jogo {inimigos = hitboxDanoJogador (jogador jogo) (inimigos jogo)}

hitboxDanoJogador :: Personagem -> [Personagem] -> [Personagem]
hitboxDanoJogador x y
    | fst (aplicaDano x) && snd (aplicaDano x) > 0 = hitboxDanoJogadoraux x y
    | otherwise = y


hitboxDanoJogadoraux :: Personagem -> [Personagem] -> [Personagem]
hitboxDanoJogadoraux _ [] = []
hitboxDanoJogadoraux player (h:t)
    | sobreposicao ((p2-tam1*aux dir,p1),(p4-tam2*aux dir,p3)) (genHitbox h) = h {vida = vida h -1 }: hitboxDanoJogadoraux player t
    | otherwise = h: hitboxDanoJogadoraux player t
    where p1 = snd (fst (genHitbox player))
          p2 = fst (fst (genHitbox player))
          p3 = snd (snd (genHitbox player))
          p4 = fst (snd (genHitbox player))
          tam1 = fst (tamanho player)
          tam2 = snd (tamanho player)
          dir = direcao player
          aux :: Direcao -> Double
          aux x
            | x == Este = -1
            | x == Oeste = 1
            | otherwise = 1
--Dano Jogador END


--Inimigo morto START
inimigoMortoEnd :: Jogo -> Jogo
inimigoMortoEnd jogo = jogo {inimigos = inimigoMorto (inimigos jogo)}

inimigoMorto :: [Personagem] -> [Personagem]
inimigoMorto = foldl (\x h-> if vida h == 0 then h {posicao = (-10,-10)} : x else h : x ) []
--Inimigo morto END


-- GRAVIDADE START
gravidadeQuedaEnd :: Double -> Jogo -> Jogo
gravidadeQuedaEnd dtime jogo = jogo {inimigos = gravidadeQueda dtime (mapa jogo) (inimigos jogo), jogador = changeVelocidade dtime (mapa jogo) (jogador jogo)}


-- | Muda a gravidade em todas as personagens que precisam de gravidade
gravidadeQueda :: Double -> Mapa -> [Personagem] -> [Personagem]
gravidadeQueda dtime mapa = map (changeVelocidade dtime mapa)
-- gravidadeQueda dtime mapa = foldl (\x y -> x ++ [changeVelocidade dtime mapa y]) []

-- | Aplica a velocidade à personagem e aplca a gravidade quando não está no chão
changeVelocidade :: Double -> Mapa -> Personagem -> Personagem
changeVelocidade dtime mapa perso
    | gravidadeQuedaonoff mapa perso = perso {
        posicao = (xPos, snd (posicao perso) + snd (velocidade perso)*dtime ),
        velocidade = (fst (velocidade perso),snd (velocidade perso)+snd gravidade*dtime)
        }
    | otherwise = perso {
        posicao = (xPos, snd (posicao perso) + snd (velocidade perso)*dtime),
        velocidade = velocidade perso -- this if resets the Y speed after falling
        }
    -- returns the X pos according to certain coditions
    where xPos = if not (podeAndarParaDireitaBool mapa perso) && fst (velocidade perso) < 0 || not (podeAndarParaEsquerdaBool mapa perso) && (fst (velocidade perso)) > 0 then
                fst (posicao perso) -- get player out of wall (??)
            else
                fst (posicao perso) + fst (velocidade perso)*dtime

-- | Deteta se a gravidade presisa de estar on ou off
gravidadeQuedaonoff :: Mapa -> Personagem -> Bool
gravidadeQuedaonoff mapa perso = not (any (sobreposicao (genHitbox perso)) (getMapColisions 1 [Plataforma,Alcapao,Tunel,Porta] (1*0.5,1*0.5) mapa)) &&
    not (any (\(x,y) -> floorPos (posicao perso) == (x,y)) (getPosOfBlockMap Escada mapa) && fst (velocidade perso) == 0)
-- GRAVIDADE END

removerjogChao :: Jogo -> Jogo
removerjogChao jog = jog {jogador = seDentroSai (mapa jog) (jogador jog)}

seDentroSai :: Mapa -> Personagem -> Personagem
seDentroSai mapa ent | not (not (any (sobreposicao ((p1,p4),(p3,p4))) (getMapColisions dimensaobloco [Plataforma,Alcapao,Tunel,Porta] (dimensaobloco*0.5,dimensaobloco*0.5) mapa))) && not (isOnBlockWithStairBelow ent mapa) =
                    ent {posicao = (fst (posicao ent),fromIntegral (floor p4)-snd (tamanho ent)*0.5),velocidade = (fst (velocidade ent),0)}
                     | otherwise = ent
                    where ((p1,p2),(p3,p4)) = genHitbox ent

isOnBlockWithStairBelow :: Personagem -> Mapa -> Bool
isOnBlockWithStairBelow jog (Mapa e j blocos) = any (\(x,y) -> floorPos (posicao jog) == (x,y-2)) (getPosOfBlock Escada blocos) &&
    any (\(x,y) -> floorPos (posicao jog) == (x,y-1) || floorPos (posicao jog) == (x,y)) (getPosOfBlock Plataforma blocos) && (snd (velocidade jog) == ladderSpeed || snd (velocidade jog) == -ladderSpeed || emEscada jog)

-- JOGADOR LIFE START
perdeVidaJogadorEnd :: Jogo -> Jogo
perdeVidaJogadorEnd jogo = jogo {jogador = perdeVidaJogador (jogador jogo) (inimigos jogo)}

perdeVidaJogador :: Personagem -> [Personagem] -> Personagem
perdeVidaJogador jog inm
    | all not (foldl (\x y -> colisoesPersonagens jog y : x ) [] inm) = jog
    | otherwise = jog {vida = vida jog - 1}
-- JOGADOR LIFE END

-- JOGADOR E OBJETOS START

coletarObjetos :: Tempo -> Jogo -> Jogo
coletarObjetos tempo jogo = jogo {colecionaveis = coletarObjetosremover (colecionaveis jogo) (jogador jogo),jogador = (jogador jogo) {pontos = isMoedaApanhada (filterObjetos (colecionaveis jogo) Moeda) (jogador jogo) (pontos (jogador jogo)),
                                                                                                                                aplicaDano = tempoDoAplicaDano (aplicaDanoFuncao (filterObjetos (colecionaveis jogo) Martelo) (jogador jogo) (aplicaDano (jogador jogo))) tempo,
                                                                                                                                temChave = pegouChave (filterObjetos (colecionaveis jogo) Chave) (jogador jogo) (temChave (jogador jogo))}}
filterObjetos :: [(Colecionavel,Posicao)] -> Colecionavel -> [(Colecionavel,Posicao)]
filterObjetos [] _ = []
filterObjetos (h:t) obj | fst h == obj = h : filterObjetos t obj
                        | otherwise = filterObjetos t obj

pegouChave :: [(Colecionavel,Posicao)] -> Personagem -> Bool -> Bool
pegouChave [] _ v = v
pegouChave (h:t) jog v  | v = True
                        | estaTocarObjeto jog (snd h) = True
                        | otherwise = pegouChave t jog v

tempoDoAplicaDano :: (Bool,Double) -> Tempo -> (Bool,Double)
tempoDoAplicaDano (a,b) tempo   | b > 0 = (a,b-tempo)
                                | b <= 0 = (False,0)

aplicaDanoFuncao :: [(Colecionavel,Posicao)] -> Personagem -> (Bool,Double) -> (Bool,Double)
aplicaDanoFuncao [] _ (v,i) = (v,i)
aplicaDanoFuncao (h:t) player (v,i) | estaTocarObjeto player (snd h) = (True,10)
                                    | otherwise = aplicaDanoFuncao t player (v,i)

isMoedaApanhada :: [(Colecionavel,Posicao)] -> Personagem -> Int -> Int
isMoedaApanhada obj player ponto = ponto + length (filter id (map (estaTocarObjeto player . snd) obj))

colecionarIndividualBool :: (Colecionavel,Posicao) -> Personagem -> Bool
colecionarIndividualBool (c,p) player   | estaTocarObjeto player p = True
                                        | otherwise = False

coletarObjetosremover :: [(Colecionavel,Posicao)] -> Personagem -> [(Colecionavel,Posicao)]
coletarObjetosremover itens player = map (`colecionarIndividual` player) itens

colecionarIndividual :: (Colecionavel,Posicao) -> Personagem -> (Colecionavel,Posicao)
colecionarIndividual (c,p) player   | estaTocarObjeto player p = (c,(-10,-10))
                                    | otherwise = (c,p)

estaTocarObjeto :: Personagem -> Posicao -> Bool
estaTocarObjeto jog pos = sobreposicao (genHitbox jog) ((fst pos-dimensaobloco*0.5,snd pos+dimensaobloco*0.5),(fst pos+dimensaobloco*0.5,snd pos-dimensaobloco*0.5))
-- JOGADOR E OBJETOS END


--JOGADOR E ALCAPAO START
acionarAlcapao :: Jogo -> Jogo
acionarAlcapao jogo = jogo {mapa = acionarAlcapaoaux (mapa jogo) (jogador jogo) Alcapao}


acionarAlcapaoaux :: Mapa -> Personagem -> Bloco -> Mapa
acionarAlcapaoaux (Mapa a b c) jog bloco = Mapa a b (removerChao (Mapa a b c) jog bloco)



removerChao :: Mapa -> Personagem -> Bloco -> [[Bloco]]
removerChao (Mapa a b c) jog bloco  | all ((==False) . sobreposicao (genHitbox jog)) (getMapColisions dimensaobloco [bloco] (dimensaobloco*0.5,dimensaobloco*0.5) (Mapa a b c)) = c
                                    | otherwise = removerAlcapao (dimensaobloco*0.5) c jog bloco

removerAlcapao :: Double -> [[Bloco]] -> Personagem -> Bloco -> [[Bloco]]
removerAlcapao _ [] _ _ = []
removerAlcapao x l jog bloco | bloco `elem` head l = removerUmAlcapao x (dimensaobloco*0.5) (head l) jog bloco : removerAlcapao (x+dimensaobloco) (tail l) jog bloco
                             | otherwise = head l : removerAlcapao (x+dimensaobloco) (tail l) jog bloco

removerUmAlcapao :: Double -> Double -> [Bloco] -> Personagem -> Bloco -> [Bloco]
removerUmAlcapao _ _ [] _ _ = []
removerUmAlcapao y x l jog bloco  | (sobreposicao ((px+0.07,p4),(px,p4)) ((px2+0.07,p6),(px2,p6)) || sobreposicao ((p1,p2),(p3,p4))  ((p5,p6),(p7,p8)) && fst (velocidade jog) == 0) && head l == bloco = Vazio : removerUmAlcapao y (x+dimensaobloco) (tail l) jog bloco
                            | otherwise = head l : removerUmAlcapao y (x+dimensaobloco) (tail l) jog bloco
                            where   ((p1,p2),(p3,p4)) = genHitbox jog
                                    ((p5,p6),(p7,p8)) = gethitboxbloco dimensaobloco (x,y)
                                    px = (p1+p3)*0.5
                                    px2 = (p5+p7)*0.5
--ALcapao END


--Logistica de movimento Start
podeAndarParaEsquerdaBool :: Mapa -> Personagem -> Bool
podeAndarParaEsquerdaBool mapa ent = all not (foldl (\x y -> sobreposicao ((p3+0.1,p2-0.1),(p3,p4-0.2)) y : x) [] (getMapColisions dimensaobloco [Plataforma,Tunel,Alcapao,Porta] (dimensaobloco*0.5,dimensaobloco*0.5) mapa)) && not (sobreposicao ((p8+1,p6),(p8,p7)) ((p1,p2),(p3,p4)))
    where ((p1,p2),(p3,p4)) = genHitbox ent
          ((p5,p6),(p7,p8)) = getMapaDimensoes dimensaobloco mapa


podeAndarParaDireitaBool :: Mapa -> Personagem -> Bool
podeAndarParaDireitaBool mapa ent = all not (foldl (\x y -> sobreposicao ((p1-0.1,p2),(p1,p4-0.2)) y : x) [] (getMapColisions dimensaobloco [Plataforma,Tunel,Alcapao,Porta] (dimensaobloco*0.5,dimensaobloco*0.5) mapa)) && not (sobreposicao ((0,0),(-p8,p7)) ((p1,p2),(p3,p4)))
    where ((p1,p2),(p3,p4)) = genHitbox ent
          ((p5,p6),(p7,p8)) = getMapaDimensoes dimensaobloco mapa

getMaprightsideEnd :: [Bloco] -> Mapa -> [Hitbox]
getMaprightsideEnd a = getMaprightside dimensaobloco a (dimensaobloco*0.5,dimensaobloco*0.5)

getMaprightside :: Double -> [Bloco] -> Posicao -> Mapa -> [Hitbox]
getMaprightside x l _ (Mapa _ _ []) = []
getMaprightside x l (a,b) (Mapa c d (h:t)) = mapablocosrightside x l (a,b) h ++ getMaprightside x l (a,b+x) (Mapa c d t)

mapablocosrightside :: Double -> [Bloco] -> Posicao -> [Bloco] -> [Hitbox]
mapablocosrightside x l _ [] = []
mapablocosrightside x l (a,b) (h:t)
    | h `elem` l = mapablocosrightside x l (a+x,b) t ++ [gethitboxrightside x (a,b)]
    | otherwise = mapablocosrightside x l (a+x,b) t

gethitboxrightside :: Double -> Posicao -> Hitbox
gethitboxrightside x (a,b) = ((a+x*0.5,b-x*0.5),(a+x*0.5,b+x*0.5))
--Logistica de movimento End





-- Ladder logic started
checkEscadas :: Jogo -> Jogo
checkEscadas jogo = jogo {
    inimigos = checkEscadaList (mapa jogo) (inimigos jogo),
    jogador = checkEscadaAux (mapa jogo) (jogador jogo)
}
    where Mapa _ _ mat = mapa jogo
          startEndEscadas = agrupaEscadas (getPosOfBlock Escada mat)

checkEscadaList :: Mapa -> [Personagem] -> [Personagem]
checkEscadaList mapa = map (checkEscadaAux mapa)

checkEscadaAux :: Mapa -> Personagem -> Personagem
checkEscadaAux (Mapa _ _ mat) perso = perso {emEscada = floorPos (posicao perso) `elem` getPosOfBlock Escada mat || any (\(x,y) -> floorPos (posicao perso) == (x,y-1)) (getPosOfBlock Escada mat) && any (\(x,y) -> floorPos (posicao perso) == (x,y)) (getPosOfBlock Plataforma mat)}

--INICIO DE AI


movimentoInimigos :: Semente -> Jogo -> Jogo
movimentoInimigos sem jogo = jogo {inimigos = movimentoInimigoscontrolo (geraAleatorios sem (length (inimigos jogo))) (mapa jogo) (inimigos jogo) jogo}

movimentoInimigoscontrolo ::[Int] -> Mapa -> [Personagem] -> Jogo -> [Personagem]
movimentoInimigoscontrolo _ _ [] _ = []
movimentoInimigoscontrolo [] _ _ _ = []
movimentoInimigoscontrolo (h:t) mapa (a:b) jogo = if tipo a == Fantasma then inimigoMove h mapa a : movimentoInimigoscontrolo t mapa b jogo else a : movimentoInimigoscontrolo t mapa b jogo

inimigoMove :: Int -> Mapa -> Personagem -> Personagem
inimigoMove start mapa enm  | read (take 3 (show start)) <= 305 && read (take 3 (show start)) >= 300 && p || inimigosubirdescerescadaBool mapa enm = inimigosubirdescerescada start mapa enm -- colar depois no True (mod (read(take 2 (show start))) 3 == 0 && p)
                            | otherwise = inimigoAndar start mapa enm
                            where p = not (all (not . sobreposicao (genHitbox enm)) (getMapColisions dimensaobloco [Escada] (dimensaobloco*0.5,dimensaobloco*0.5) mapa))



inimigoAndar :: Int -> Mapa -> Personagem -> Personagem
inimigoAndar start mapa enm     | fst (velocidade enm) == 0 = if start > 0 then enm {velocidade = (1.5,0)} else enm {velocidade = (-1.5,0)}
                                | not (podeAndarParaEsquerdaBool mapa enm) = enm {velocidade = (-1.5,0)}
                                | not (podeAndarParaDireitaBool mapa enm) = enm {velocidade = (1.5,0)}
                                | all not (foldl (\x y -> sobreposicao ((p1,p4),(p1-0.1,p4-0.5)) y : x) [] (getMapColisions dimensaobloco [Plataforma,Alcapao,Porta] (dimensaobloco*0.5,dimensaobloco*0.5) mapa)) = enm {velocidade = (1.5,0)}
                                | all not (foldl (\x y -> sobreposicao ((p3,p4),(p3+0.1,p4-0.5)) y : x) [] (getMapColisions dimensaobloco [Plataforma,Alcapao,Porta] (dimensaobloco*0.5,dimensaobloco*0.5) mapa)) = enm {velocidade = (-1.5,0)}
                                | otherwise = enm {velocidade = (fst (velocidade enm),0)}
                                where ((p1,p2),(p3,p4)) = genHitbox enm
                                      p = not (all (not . sobreposicao (genHitbox enm)) (getMapColisions dimensaobloco [Plataforma,Tunel,Alcapao,Porta] (dimensaobloco*0.5,dimensaobloco*0.5) mapa))

inimigosubirdescerescada :: Int -> Mapa -> Personagem -> Personagem
inimigosubirdescerescada start mapa enm = if not (all (not . sobreposicao ((p1+0.3,p4),(p3-0.3,p4))) (getMapColisions dimensaobloco [Vazio] (dimensaobloco*0.5,dimensaobloco*0.5) mapa))
                                            then enm {velocidade = (if fst (velocidade enm) == 0 then 1.5 else fst (velocidade enm),0), posicao = (fst (posicao enm),fromInteger (floor (snd (posicao enm)))+0.5)}
                                            else enm {velocidade = (0,-1.5)}
                                        where ((p1,p2),(p3,p4)) = genHitbox enm

inimigosubirdescerescadaBool :: Mapa -> Personagem -> Bool
inimigosubirdescerescadaBool mapa enm = fst (velocidade enm) == 0 && snd (velocidade enm) /= 0


--Portas Start



portasFuncao :: Jogo -> Jogo
portasFuncao jogo = if not (temChave (jogador jogo)) then jogo {mapa = mapa jogo} else jogo {mapa = m, jogador = (jogador jogo) {temChave = m == (mapa jogo) && temChave (jogador jogo)}}
                    where m = podeabrirporta (mapa jogo) (jogador jogo)

podeabrirporta :: Mapa -> Personagem -> Mapa
podeabrirporta mapa player = acionarBlocoGeral mapa player Porta

acionarBlocoGeral :: Mapa -> Personagem -> Bloco -> Mapa
acionarBlocoGeral (Mapa a b c) jog bloco = Mapa a b (removerBloco (Mapa a b c) jog bloco)


removerBloco :: Mapa -> Personagem -> Bloco -> [[Bloco]]
removerBloco (Mapa a b c) jog bloco | all ((==False) . sobreposicao ((p1-0.1,p2),(p3+0.1,p4))) (getMapColisions dimensaobloco [bloco] (dimensaobloco*0.5,dimensaobloco*0.5) (Mapa a b c)) = c
                                    | otherwise = removerBloco2 (dimensaobloco*0.5) c jog bloco
                                    where ((p1,p2),(p3,p4)) = genHitbox jog

removerBloco2 :: Double -> [[Bloco]] -> Personagem -> Bloco -> [[Bloco]]
removerBloco2 _ [] _ _ = []
removerBloco2 x l jog bloco | bloco `elem` head l = removerUmBloco x (dimensaobloco*0.5) (head l) jog bloco : removerBloco2 (x+dimensaobloco) (tail l) jog bloco
                            | otherwise = head l : removerBloco2 (x+dimensaobloco) (tail l) jog bloco

removerUmBloco :: Double -> Double -> [Bloco] -> Personagem -> Bloco -> [Bloco]
removerUmBloco _ _ [] _ _ = []
removerUmBloco y x l jog bloco  | sobreposicao ((p1-1,p2),(p3+1,p4)) ((p5,p6),(p7,p8)) && head l == bloco = Vazio : removerUmBloco y (x+dimensaobloco) (tail l) jog bloco
                                | otherwise = head l : removerUmBloco y (x+dimensaobloco) (tail l) jog bloco
                            where   ((p1,p2),(p3,p4)) = genHitbox jog
                                    ((p5,p6),(p7,p8)) = gethitboxbloco dimensaobloco (x,y)


--Portas End

--Macaco Malvado

movimentoMacacoMalvado :: Tempo -> Jogo -> Jogo
movimentoMacacoMalvado tempo jogo = jogo {inimigos = aimacacomalvado tempo (inimigos jogo) (jogador jogo)}

aimacacomalvado :: Tempo -> [Personagem] -> Personagem-> [Personagem]
aimacacomalvado tempo enm p = ataqueMacacoBarril tempo (foldl (\x y -> if tipo y == MacacoMalvado then aimacacomalvadoaux tempo y p : x else y : x) [] enm)

aimacacomalvadoaux :: Tempo -> Personagem -> Personagem -> Personagem
aimacacomalvadoaux tempo enm jogador = enm  {posicao = if fst (posicao enm) < fst (posicao jogador)+0.2 && fst (posicao enm) > fst (posicao jogador)-0.2 then posicao enm else (if fst (posicao enm) > fst (posicao jogador) then fst (posicao enm)-(2*tempo) else fst (posicao enm)+(2*tempo),snd (posicao enm)) ,
                                             velocidade = if fst (posicao enm) > fst (posicao jogador) then (-2,0) else (2,0),
                                             aplicaDano = if snd (aplicaDano enm) <= 0 then (True,8) else (snd (aplicaDano enm) > 7, snd (aplicaDano enm)-tempo)}

ataqueMacacoBarril :: Tempo -> [Personagem] -> [Personagem]
ataqueMacacoBarril tempo lista  | barril == [] = macaco ++ resto
                                | macaco == [] = barril ++ resto
                                | otherwise = ataqueMacacoBarrilaux tempo (head barril) (head macaco) : (macaco ++ resto)
                                where (barril,macaco,resto) = foldl (\(a,b,c) y -> if tipo y == MacacoMalvado then (a, [y],c) else if tipo y == Barril then ([y], b, c) else (a,b, y : c)) ([],[],[]) lista


ataqueMacacoBarrilaux :: Tempo -> Personagem -> Personagem -> Personagem
ataqueMacacoBarrilaux tempo barril macaco | snd(aplicaDano macaco) == 8 = barril {posicao = posicao macaco,velocidade = (0,1)}
                                          | otherwise = barril {posicao = (fst(posicao barril), snd(posicao barril) + (snd(velocidade barril))*tempo)}



