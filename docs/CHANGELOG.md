# Histórico

## 0.2.0 — Movimento, cotidiano e controle

O clique para caminhar usava intervalos maiores que o teclado e passava a sensação de personagem lento. Agora um passo leva 0,14 segundo real a 1×, com pequena penalidade de cansaço, movimento visual suavizado e primeiro passo imediato. O movimento direto respeita o mesmo limite mesmo com muitos eventos ou frames. Clique redireciona; Shift preserva a fila.

Bia e Caio passam a ter necessidades, estoque, saldo e atividades. Comem, descansam, leem, tomam banho, usam banheiro e conversam entre si. A escolha de atividade calcula e guarda uma rota; não recalcula caminhos a cada frame. Reservas de NPCs não são removidas ao cancelar ações do jogador. Casas particulares têm autorização própria.

A casa ganhou pisos por ambiente, divisórias, portas visuais e pontos de uso validados. NPCs recebem poses de atividade e orientação. A cama, o sofá e o banheiro continuam acessíveis após a mudança.

O controle Xbox permite começar e jogar sem teclado físico: teclado de nome, menus com foco, interação próxima, lista de ações e cursor. O menu principal reúne as telas de gestão. LT/RT controlam zoom, LB/RB o tempo, View pausa e Start abre o menu. Há zona morta e pausa na desconexão. Rótulos seguem o dispositivo em uso.

O formato de save passa a v2. Saves v1 recebem o estado novo dos NPCs, orientação e duração da visita. Rotas antigas são recalculadas se uma divisória nova ocupar sua passagem, mantendo o registro de comida ou pagamento já consumado.

Validação: 132 verificações automatizadas passaram. Dias completos em 1×, 2× e 3× incluem atividades e evento de turno único. Eventos de controle atravessam o criador, teclado na tela, navegação, cursor, interações e trabalho. A renderização foi conferida em display virtual; controle físico, Windows e avaliação prolongada do ritmo continuam dependendo de testes no computador do jogador.

## 0.1.1 — Reconstrução

Base da Etapa 1 reconstruída após a sessão anterior ficar indisponível, com necessidades, casa, vizinhos, um emprego e save. Foi entregue pelo GitHub e executada pelo jogador.
