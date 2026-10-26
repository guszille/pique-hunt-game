# Pique-Prop

Pique-esconde multiplayer 3D no estilo *prop hunt*, feito em Godot 4.7 (GDScript).
Todos os jogadores são aliens que conseguem imitar objetos. A cada rodada um deles é
sorteado para procurar; os outros se escondem e podem virar objetos do cenário.

O alien tem a cor escolhida pelo jogador. O procurador usa visor vermelho, mochila
e scanner, e as pontas das antenas ficam vermelhas.

## Como jogar

1. Um jogador clica em **Hospedar partida**. O lobby mostra o IP dele na rede.
2. Os outros digitam esse IP e clicam em **Entrar** (porta UDP 7777).
3. O host escolhe o modo e clica em **Iniciar partida** (mínimo de 2 jogadores).

Os **tempos automáticos** vêm ligados: a preparação e a caçada se ajustam ao mapa
escolhido (ou ao vencedor da votação) e ao número de jogadores. Cada escondido acima
de 3 soma 15 s de caçada, até 10 min. Desligue a opção para escolher os tempos à mão.

O mapa pode ser fixado pelo host ou ficar em **Votação dos jogadores**, que é o
padrão. Na votação, cada um clica no mapa que prefere e pode mudar o voto até o
início.

- Vence o mapa mais votado.
- Em caso de empate, o jogo sorteia entre os mapas empatados.
- Se ninguém votar, o jogo sorteia entre todos os mapas.

O resultado aparece na tela no começo da partida, e a votação recomeça sempre
que o grupo volta ao lobby.

### Idioma

O jogo está em **português** e **inglês**. Escolha o idioma no menu principal ou no
menu de pausa (Esc); a escolha fica salva. Na primeira vez, o jogo usa português se
o sistema estiver em português e inglês nos outros casos. Cada jogador vê a partida
no próprio idioma, inclusive os avisos do host.

Cada rodada passa por: **Sorteio → Preparação** (o procurador fica preso e com a tela
escura) **→ Caçada → Fim** (placar). Depois começa uma nova rodada com outro procurador.

| Tecla | Escondido | Procurador |
|---|---|---|
| WASD / mouse | andar / câmera | andar / câmera |
| Espaço | pular | pular |
| E | virar o objeto mirado (o nome dele aparece embaixo da mira) | — |
| Q | voltar a ser alien | — |
| R | travar a rotação do objeto | — |
| Shift (segurar) | congelar | — |
| Clique esquerdo | — | pegar (de perto). Errar num objeto deixa você lento |
| Tab | placar | placar |
| Esc | pausa | pausa |

### Disfarces

Dá para virar móveis e objetos compostos (geladeira, sofá, cama, mesa, xícara
maluca, pedalinho...) e também objetos simples (bola, arbusto, lata). A cópia fica
idêntica ao original, inclusive nas cores.

- Ao virar um objeto, você começa com a mesma rotação dele, já travada. Assim fica
  alinhado com a parede como o original; aperte R para destravar.
- Objetos pequenos andam devagar. Os médios (cadeira, lixeira) andam quase como
  o alien, e os pesados (geladeira, sofá, cama, guarda-roupa) andam e pulam devagar.
- A câmera se afasta e sobe com objetos grandes.
- Mesas, camas, berços e bancos têm vão embaixo: objetos pequenos cabem ali.

### Modos

- **Clássico:** quem é pego sai da rodada e assiste voando pelo mapa.
- **Infecção:** quem é pego volta à forma de alien e vira **ajudante do procurador**,
  com o equipamento do procurador em verde.
  - O ajudante precisa esperar 3 s antes de poder pegar alguém, para quem estava
    perto conseguir fugir.
  - O time do procurador vence quando todo mundo for infectado.
  - Pontos: cada captura vale +3 para quem pegou, inclusive ajudantes. Se o time
    do procurador vencer, o procurador original ganha +5 e cada ajudante ganha +2.
  - Se o procurador original sair, a rodada continua enquanto houver ajudantes.

Pontos: o procurador ganha +3 por captura e +5 se pegar todo mundo. Cada escondido
ganha +1 a cada 30 s vivo e +5 se sobreviver. No último minuto, os escondidos
assobiam de tempos em tempos.

## Estrutura

```
autoload/language.gd     idioma escolhido e tradução das mensagens do host
autoload/controls.gd     ações de input
autoload/network.gd      ENet (host/cliente) e lista de jogadores
autoload/game_state.gd   fases da rodada, sorteio, capturas, disfarces, pontos (servidor)
autoload/debug_tools.gd  modo de depuração: teste solo e teclas F1–F6
scripts/prop_builder.gd  gera malhas/colisões de primitivas e de objetos compostos
scripts/prop_catalog.gd  catálogo de objetos compostos (junta as listas abaixo)
scripts/catalog/         objetos de cada mapa: house_items, factory_items, park_items
scripts/sfx.gd           sons sintetizados em código
scenes/props/prop.*      objeto do cenário (disfarçável ou decoração)
scenes/player/player.*   jogador em 3ª pessoa (MoveSync = dono, StateSync = servidor)
scenes/player/alien_model.gd  visual e animação do alien, montado com primitivas
scenes/game/game.*       partida: mapa + spawner de jogadores + HUD
scenes/maps/house.tscn   mapa "Casa", gerado por tools/build_house.gd
scenes/maps/factory.tscn mapa "Fábrica", gerado por tools/build_factory.gd
scenes/maps/park.tscn    mapa "Parque", gerado por tools/build_park.gd
tools/map_builder.gd     base dos geradores de mapa (paredes, pisos, objetos, aviso de sobreposição)
tools/export.sh          exporta para Linux e Windows (build/)
tools/check_translations.py  confere se todos os textos têm tradução em locale/en.po
locale/en.po             traduções para o inglês
scenes/ui/               menu, lobby e HUD
```

### Traduções

Os textos são escritos em português no código (`tr("...")`) e nas cenas, e o
próprio texto em português é a chave da tradução. As versões em inglês ficam em
`locale/en.po`, que pode ser editado à mão ou no Poedit.

- Avisos que o host manda para todos (capturas, resultado, votação) viajam como
  `[chave, args...]` e cada jogador traduz com `Language.format()`. Argumentos
  `StringName` (como nomes de mapa) também são traduzidos; `String` não (nomes de
  jogadores).
- Os nomes dos objetos do catálogo e de `PRIMITIVE_LABELS` também são chaves.
- Depois de criar ou mudar textos, rode `python3 tools/check_translations.py`: ele
  lista o que falta traduzir e o que sobrou no `.po`.
- Para testar, `-- --lang=en` (ou `--lang=pt_BR`) força o idioma sem salvar.

O mapa é um `MapBase` com os nós `HiderSpawns`, `SeekerCage` e `SeekerRelease`. Os
objetos são instâncias de `prop.tscn`:

- **Objeto do catálogo:** escolha o `kind` no inspetor (lista com todos os objetos)
  e, se quiser, troque as cores de cada parte em `colors`.
- **Primitiva:** deixe `kind` vazio e ajuste `shape`, `size` e `color`.
- Desmarque `disguisable` para o que não deve ser copiado (bancadas, carro, sinuca).

Para criar um objeto composto, acrescente-o numa das listas de `scripts/catalog/`.
Cada objeto é um conjunto de peças (forma, tamanho, posição, rotação e cor) com a
frente virada para +Z; as caixas de colisão são opcionais (sem elas, vale a caixa
envolvente).

Para adicionar um mapa, crie a cena com essa estrutura e registre-a em
`GameState.MAPS`.

### Mapas

- **Casa:** sobrado com quatro níveis ligados por escadas, 276 objetos disfarçáveis.
  - Térreo: hall, sala de TV, sala de jantar, cozinha, despensa, banheiro com
    chuveiro, escritório, lavanderia e garagem com carro.
  - Andar de cima: quarto do casal, quarto de criança, quarto do bebê (com berço),
    banheiro com banheira, sala íntima e quarto de hóspedes.
  - Porão: sinuca, caldeira, adega e móveis cobertos com lençol.
  - Sótão: baús, malas, caixas e móveis cobertos, com teto baixo nas laterais.
  - Quintal com churrasqueira, casinha de cachorro e mesas de jardim.
- **Fábrica:** galpão de 7 m com anexos e pátio, 319 objetos disfarçáveis.
  - Galpão: esteiras, estoque com prateleiras, barris, oficina, vestiário, docas e
    mezanino com escritório. Passarelas a 4,5 m nas paredes norte e leste, com
    escadas a partir do chão e do mezanino.
  - Anexo oeste: refeitório, escritório com baias e casa de máquinas no subsolo.
  - Anexos norte: almoxarifado com corredores de prateleiras e câmara fria.
  - Pátio: contêineres empilhados, caminhão-baú aberto (dá para entrar),
    bobinas, pallets e guarita.
- **Parque:** parque de diversões ao entardecer, 315 objetos disfarçáveis.
  - Parte antiga: carrossel, roda-gigante, bate-bate, barracas, praça de
    alimentação, piscina de bolinhas, labirinto de espelhos e trem fantasma.
  - Ao norte: palco com plateia de cadeiras iguais, lago com píer e pedalinhos de
    cisne, montanha-russa com área cheia de pilares embaixo.
  - A leste: xícaras malucas, mini golfe, fliperama coberto, loja de prêmios com
    ursos gigantes e banheiros.

  Os brinquedos ficam parados.

Escadas e rampas: como o jogador não sobe degraus de verdade, cada escada tem uma
rampa invisível por cima dos degraus e um bloco sólido embaixo dela, para ninguém
entrar no vão da escada (`stairs()` em `tools/map_builder.gd`).

Portas: a largura de um vão no gerador é a largura livre real. Use `door()` com
`DOOR` (1,1 m, portas comuns) ou `MAIN_DOOR` (1,4 m, entradas e áreas de serviço);
o alien tem 0,7 m de largura.

Os mapas são gerados por código. Para refazer um mapa:

```bash
../Godot_v4.7.2-stable_linux.x86_64 --headless --path . -s res://tools/build_factory.gd
```

O gerador sobrescreve a cena e avisa se algum objeto atravessa outro ou uma parede,
se uma passagem tem menos de 1 m livre ou se algum objeto está no caminho de uma porta.
Depois de editar um mapa no editor, não rode o gerador dele de novo.

## Exportar (gerar o jogo para distribuir)

Requer os modelos de exportação do Godot 4.7.2, que você instala em *Editor →
Gerenciar modelos de exportação*. Depois rode:

```bash
tools/export.sh
```

O script gera um executável único (com os dados embutidos) para cada sistema e um
`.zip` de cada um em `build/`:

- `build/PiqueProp-<versão>-linux.zip` contém `PiqueProp.x86_64`. No Linux, talvez
  seja preciso rodar `chmod +x PiqueProp.x86_64` antes de abrir.
- `build/PiqueProp-<versão>-windows.zip` contém `PiqueProp.exe`. Por não ser
  assinado, o Windows pode mostrar o aviso do SmartScreen. Clique em
  *Mais informações → Executar assim mesmo*.

A versão vem de `config/version` no `project.godot` e aparece no rodapé do menu
principal. Todos os jogadores precisam da mesma versão.

Ao conectar, o jogo confere a versão antes de deixar o jogador entrar:

- **Versão diferente da do host:** o jogador volta ao menu com uma mensagem como
  "Versões diferentes: você tem a 0.2.0 e o host tem a 0.2.1".
- **Host com uma versão anterior à 0.2.1** (sem a checagem): depois de alguns
  segundos aparece "O host não respondeu à checagem de versão".
- **Cópias anteriores à 0.2.1 entrando num host novo:** elas não têm a checagem,
  então só aparece "A conexão com o host caiu".

Suba `config/version` sempre que distribuir uma build nova.

## Jogar em rede local (LAN)

1. Todos no mesmo roteador. Redes de convidados ou com isolamento de clientes
   (AP isolation) bloqueiam a conexão.
2. Quem hospeda clica em **Hospedar partida**. O lobby mostra o IP dele.
3. Os outros digitam esse IP e clicam em **Entrar**.

O jogo usa a porta **UDP 7777**. Se não conectar, libere essa porta no firewall de
quem hospeda (no Linux: `sudo ufw allow 7777/udp`; no Windows: aceite o aviso do
firewall). Para jogar pela internet sem abrir portas, use uma VPN como Tailscale
ou ZeroTier e conecte pelo IP que ela fornece.

## Modo de depuração (testar sozinho)

Rodando pelo editor (F5) ou por `godot --path .`, o jogo é uma build de
depuração. As builds geradas por `tools/export.sh` são de release e não têm
nada disto.

- **Teste solo:** hospede a partida e clique em **Iniciar partida** sozinho. Ninguém
  procura: você começa escondido, o sorteio é pulado e a rodada só acaba pelo tempo.
- **Teclas durante a partida** (a legenda aparece em amarelo no rodapé):

| Tecla | Efeito |
|---|---|
| F1 | troca entre escondido e procurador (quem vira procurador assim não fica cego) |
| F2 | câmera livre: WASD + mouse, Espaço sobe, Shift desce. F2 de novo volta ao jogador |
| F3 | mostra as colisões: azul = mundo, laranja = objetos, rosa = jogadores |
| F4 | pula para a próxima fase (preparação → caçada → fim → nova rodada) |
| F5 | troca para o próximo mapa (Casa → Fábrica → Parque) |
| F6 | pausa e retoma o cronômetro |

F1, F4, F5 e F6 valem para a partida inteira e aparecem como aviso para todos.
F2 e F3 só mudam a sua tela. As teclas também funcionam com várias instâncias,
desde que o host seja uma build de depuração.

Partida solo direto pela linha de comando, já no Parque e com caçada longa:

```bash
../Godot_v4.7.2-stable_linux.x86_64 --path . -- --host --name=Ana --autostart=1 --map=2 --hunt=900
```

Para testar as regras normais (mínimo de 2 jogadores, sem teclas F) numa build de
depuração, acrescente `--no-debug` depois do `--`.

Se o jogo estiver embutido na aba *Jogo* do editor e alguma tecla F não responder,
clique dentro do jogo antes de apertar, ou desative a opção de embutir a janela
nessa aba.

## Testes locais (várias instâncias)

```bash
GODOT=../Godot_v4.7.2-stable_linux.x86_64
$GODOT --path . -- --host --name=Ana --autostart=3 --prep=10 --hunt=60 &
$GODOT --path . -- --join=127.0.0.1 --name=Bia &
$GODOT --path . -- --join=127.0.0.1 --name=Caio &
```

Opções de teste:
- `--autostart=N`: o host inicia sozinho quando N jogadores entrarem (`1` = teste solo, só em depuração).
- `--map=I`: mapa usado no autostart (-1 = votação, 0 = Casa, 1 = Fábrica, 2 = Parque).
- `--mode=I`: modo usado no autostart (0 = Clássico, 1 = Infecção).
- `--prep` / `--hunt`: tempos de preparação e caçada, em segundos.
- `--screenshot=arquivo.png --screenshot-delay=S`: salva uma captura da partida.
- `--no-debug`: desliga o modo de depuração (teste solo e teclas F1–F6).
- `--headless`: roda sem janela.
