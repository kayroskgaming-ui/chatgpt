# Minha Vida — Histórias da Cidade

**Versão 0.2.0 · cotidiano e suporte a controle.** Simulador de vida em português brasileiro no Bairro Ipê, em Vila Aurora. Use **Godot 4.6.3 estável, edição padrão GDScript**, com renderizador **Compatibility**. Sem plugins externos.

## Baixar, atualizar e jogar no Windows

1. No GitHub, selecione a branch **minha-vida-recuperacao**.
2. Clique em **Code → Download ZIP** e depois **Extrair Tudo** no Windows.
3. Extraia em uma pasta nova para manter uma cópia do projeto anterior.
4. No Godot 4.6.3, clique em **Importar**, selecione `project.godot` na pasta nova e abra o projeto.
5. Pressione **F5** no editor. Escolha **Continuar jogo salvo** ou crie seu personagem.

O save da versão 0.1.1 é migrado automaticamente para o formato v2. A posição e a rota são ajustadas caso uma nova divisória ocupe o local anterior, sem repetir consumo ou cobrança. A versão anterior do arquivo continua em `vida.json.bak` após o próximo salvamento. Para preservar uma cópia permanente, abra a pasta de dados do usuário no editor Godot e copie `vida.json` antes de atualizar.

Este pacote é um projeto editável, não um executável pronto nem um jogo de navegador. O preset Windows x64 está incluído, mas exportação e execução do EXE não foram validadas. Godot oficial: https://godotengine.org/download/archive/4.6.3-stable/.

## Novidades da 0.2.0

- **Caminhada:** passos mais rápidos, resposta no primeiro tick e suavização visual. Clique em outro destino durante uma caminhada para redirecionar; segure Shift para acrescentar destinos. Teclado e controle usam o mesmo intervalo, independente da taxa de frames. Diagonais não cortam cantos de paredes.
- **Vizinhos:** Bia e Caio têm seis necessidades, estoque de refeições, dinheiro próprio, casa e rotas persistentes. Procuram comida, cama, banheiro, banho, leitura e conversa. Rotinas de trabalho e passeio usam caminhos; atividades reservam os móveis e liberam-nos ao terminar. NPCs cedem passagem quando bloqueados. Caio agora tem uma casa própria, ainda sem visitas do jogador.
- **Casa:** quarto, sala, cozinha e banheiro com pisos próprios, divisórias sólidas e passagens. Portas abrem visualmente na aproximação autorizada. Telhados continuam aparecendo por fora e desaparecendo por dentro. Pontos de uso ficam no mesmo imóvel, sem interações através de paredes.
- **Animações:** movimento com orientação, pernas e braços, poses alinhadas de dormir/sentar, livro no sofá, comida na mão, água no banho e indicação de conversa. NPCs também exibem suas atividades; são animações procedurais provisórias.
- **Controle Xbox:** movimento, interações próximas, cursor virtual, criação com teclado de nome na tela, foco e navegação dos menus, decisões do turno, pausa, tempo, câmera e zoom. Desconectar o controle pausa o jogo.
- **Validação:** roteiros de um dia completo em 1×/2×/3× com alimentação, higiene, banheiro, visita, aviso de trabalho e pagamento único, além de migração e retomada de saves.

## Controles Xbox

Conecte um controle reconhecido pelo sistema, por USB ou Bluetooth. Os rótulos mudam quando você usa o controle. Mouse e teclado continuam disponíveis.

| Comando | Função |
|---|---|
| Analógico esquerdo ou direcional | Andar; nos menus, navegar |
| A | Interagir com alvo próximo; confirmar seleção |
| B | Cancelar ações no bairro; voltar nos menus |
| X | Listar móveis, moradores e entradas próximos |
| Y | Abrir destinos do bairro |
| Analógico direito | Mover cursor virtual para selecionar com A |
| Clique do analógico direito | Ocultar cursor e voltar a seguir o personagem |
| LT / RT | Diminuir / aumentar zoom |
| LB / RB | Reduzir / aumentar velocidade do tempo |
| View (Back) | Pausar / retomar |
| Menu (Start) | Abrir / fechar menu principal |

No criador, A sobre o campo de nome abre o teclado na tela. Use direcional/analógico para navegar, A para escrever e B para voltar. O menu principal dá acesso a configurações, salvar/carregar, finanças, inventário, vizinhos e destinos. A decisão de trabalho exige escolher ir, adiar ou faltar; B não descarta esse aviso.

**Limitação de validação:** os testes do controle usam eventos de joystick enviados ao sistema de entrada real do Godot, incluindo confirmação de menus e cursor. Não houve teste com controle físico, Bluetooth, Steam Input ou hardware Windows nesta máquina. Mapeamentos de dispositivos não reconhecidos como Xbox podem variar. Não há vibração, remapeamento ou ícones específicos de PlayStation nesta entrega.

## Mouse e teclado

| Comando | Função |
|---|---|
| Clique no chão | Caminhar / redirecionar caminhada |
| Shift + clique | Acrescentar destino à fila |
| Clique em casa, pessoa ou objeto | Abrir ações disponíveis |
| WASD | Movimento direto; substitui a fila |
| Roda do mouse | Zoom em níveis |
| Arrastar com botão do meio | Observar o bairro |
| C | Seguir o personagem |
| Espaço / 1 / 2 / 3 | Pausa / velocidades |
| X | Cancelar fila, inclusive dormir |
| F5 / F9 na janela do jogo | Salvar / carregar |
| M / Esc | Destinos / menu |
| F3 | Mostrar colisões, rotas e pontos de uso |

F5 no editor inicia o projeto; F5 na janela do jogo salva.

## Base jogável preservada

Criação de adulto com nome, aparência, pronomes e traço; seis necessidades, humor e conforto; calendário e ciclo de iluminação; casa habitável, praça, Café da Esquina e vizinhos; fila e autonomia opcionais; campainha da Bia com aceitação/recusa. Convites duram quatro horas e expiram após sair.

Barista trabalha de segunda a sexta, 09:00–13:00, por V$ 120 no turno integral. Há aviso, pop-up, transporte automático, adiamento de 15 minutos, falta, postura e salário proporcional ao atraso, registrado uma única vez no extrato. O Café vende lanche por V$ 12 e café por V$ 4 entre 08:00 e 18:00.

Salvamento manual e automático a cada três horas do jogo, com arquivo temporário e backup. Estado dos moradores, estoque, fila, reservas e expediente persistem. Os testes usam arquivos próprios, sem sobrescrever o save do jogador.

## Limitações e próximas etapas

A arte continua procedural e provisória, com um penteado e orientação simplificada, sem sprites direcionais completos. A casa tem divisórias e aberturas de leitura simplificada, sem um editor de construção. A aspiração é fixa. Não há diálogos elaborados nem qualidade ambiental detalhada. Os vizinhos têm uma simulação pequena e usam trajetos por grade; não há trânsito ou regras completas de calçadas. A reposição de sua comida é simplificada, com desconto do saldo doméstico, sem visita a um supermercado. Há visita à Bia; a casa do Caio é apenas para a rotina dele.

A casa do jogador é cedida. Aluguel, contas, imobiliária, supermercado, culinária, validade dos alimentos, entregas, decoração, outras carreiras, promoções, romance, famílias, outros bairros, veículos e negócios próprios ainda não estão implementados. O menu de mapa é uma lista de destinos. Essas funções serão introduzidas por etapas, mantendo uma versão jogável.

## Desenvolvimento e testes na nuvem

```bash
bash tools/setup.sh   # confere Godot, importa e testa
bash tools/check.sh   # quatro suítes; também falha em erros GDScript
bash tools/start.sh   # requer display gráfico
```

Os scripts usam diretórios graváveis em `/workspace/.runtime` para dados/config/cache. Em um computador comum, abra pelo editor: o save fica em `user://vida.json` na pasta de dados padrão do Godot.

- `city.gd`: mapa, imóveis, cômodos, sólidos, pontos de uso e caminhos.
- `simulation.gd`: tempo, necessidades, ações, estoque, economia e carreira.
- `neighborhood.gd`: necessidades, atividades, rotinas e reservas dos moradores.
- `world.gd`: desenho isométrico, poses, portas, telhados e câmera.
- `controller.gd`: entrada do controle, zona morta, cursor e ações de interface.
- `main.gd`: interface, menus, teclado de nome e autosave.
- `save_store.gd`: validação, migração v1→v2, backup e recuperação.

**132 verificações passaram:** 40 de regressão, 16 de interface, 42 de cotidiano/migração/dias completos e 34 de controle. Veja [resultados](docs/testes.txt) e [histórico da versão](docs/CHANGELOG.md). Capturas em [docs/capturas](docs/capturas) vêm do viewport real do Godot, executado com Xorg virtual e Mesa llvmpipe/Compatibility.
