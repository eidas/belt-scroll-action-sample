# 実装計画

> 本ドキュメントは `docs/game_spec.md` に基づく、Phase 単位の詳細な実装計画である。
> 各タスクは **1つのコミットで完結できる粒度** を目安に分割している。

---

## Phase 1: プロジェクト基盤構築

プロジェクトの骨格を作り、以降の全 Phase が依存する土台を整える。

### 1-1. Godot プロジェクト初期化

- `project.godot` を作成
- プロジェクト名: `BeltScrollAction`
- 表示設定
  - ベース解像度: 384×224
  - ストレッチモード: `canvas_items`（ピクセルパーフェクト）
  - ウィンドウサイズ: 1152×672（3倍）
  - テクスチャフィルタ: `Nearest`（ドット絵用）
- 物理設定: 60fps 固定
- レンダラー: `Forward+` → `Compatibility`（2D のため軽量レンダラー）

### 1-2. ディレクトリ構成の作成

仕様書 10.1 に従い、以下のディレクトリツリーを作成する。
空ディレクトリには `.gdkeep` を配置して Git 追跡する。

```
project/
├── scenes/{main, stages, characters/player, characters/enemy/bosses, objects/items, objects/destructibles, ui}
├── scripts/{autoload, characters, combat, stage}
├── resources/{character_data, stage_data}
├── assets/{sprites, audio/bgm, audio/sfx, fonts}
```

### 1-3. Autoload スケルトン作成

以下の4つの Autoload シングルトンを空スクリプトとして作成し、`project.godot` に登録する。

| スクリプト | 役割 | 初期実装内容 |
|-----------|------|-------------|
| `game_manager.gd` | ゲーム状態管理 | `GameState` enum（TITLE, SELECT, PLAYING, PAUSED, GAMEOVER, ENDING）、現在ステート保持 |
| `input_manager.gd` | 入力管理 | 1P/2P のデバイスマッピング、方向入力・ボタン入力の取得メソッド |
| `score_manager.gd` | スコア管理 | スコア変数、加算メソッド、リセットメソッド |
| `audio_manager.gd` | 音声管理 | BGM/SE 再生メソッドのスタブ |

### 1-4. 入力マッピング定義

`project.godot` の Input Map に以下を定義する。

| アクション名 | キーボード(1P) | ゲームパッド |
|-------------|---------------|-------------|
| `p1_up` | W | 左スティック上 / D-Pad上 |
| `p1_down` | S | 左スティック下 / D-Pad下 |
| `p1_left` | A | 左スティック左 / D-Pad左 |
| `p1_right` | D | 左スティック右 / D-Pad右 |
| `p1_attack` | J | Xボタン |
| `p1_jump` | K | Aボタン |
| `p1_special` | L | Yボタン |
| `pause` | Escape | Start |

- 2P はゲームパッド Device 1 に同様のアクション (`p2_*`) を割り当て
- `input_manager.gd` でプレイヤー番号からアクション名を解決するヘルパーを提供

### 1-5. テスト用ステージシーンの作成

開発中の動作確認に使う最小限のテストステージを用意する。

- `scenes/stages/test_stage.tscn`
  - Node2D ルート
  - 背景用の ColorRect（仮背景）
  - 地面・壁の StaticBody2D（歩行可能範囲の定義）
  - Camera2D（仮配置）
- このシーンを `project.godot` のメインシーンに設定

---

## Phase 2: プレイヤー基本動作

プレイヤーキャラクターの移動・アニメーション・ステートマシンを実装する。

### 2-1. キャラクターデータリソースの定義

キャラクター固有パラメータを保持するカスタムリソースを作成する。

```
scripts/resources/character_data.gd (extends Resource)
```

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `character_name` | String | キャラクター名 |
| `max_hp` | int | 最大HP |
| `attack_power` | int | 基本攻撃力 |
| `move_speed` | float | 移動速度 |
| `dash_speed` | float | ダッシュ速度 |
| `jump_force` | float | ジャンプ力 |
| `combo_count` | int | 最大コンボ段数 |
| `grab_power` | int | 投げダメージ |
| `special_hp_cost` | int | 必殺技HP消費量 |
| `sprite_frames` | SpriteFrames | アニメーション |

3キャラ分の `.tres` を `resources/character_data/` に作成する。

### 2-2. プレイヤーシーン構築

`scenes/characters/player/player.tscn` を作成する。

```
Player (CharacterBody2D)
├── Sprite (AnimatedSprite2D)          # キャラクタースプライト
├── ShadowSprite (Sprite2D)            # 足元の影（奥行き視認用）
├── CollisionShape (CollisionShape2D)  # 物理ボディ用
├── Hitbox (Area2D)                    # 攻撃判定（子に CollisionShape2D）
├── Hurtbox (Area2D)                   # 被弾判定（子に CollisionShape2D）
├── GrabPoint (Marker2D)              # 掴み位置
├── StateMachine (Node)                # ステートマシン管理ノード
└── AnimationPlayer                    # エフェクト用アニメーション
```

- `player_controller.gd` をルートにアタッチ
- `Hitbox` は通常時は無効。攻撃アニメーション中のみ有効化

### 2-3. ステートマシン実装

`scripts/characters/player_state_machine.gd` を実装する。

**ステート基底クラス** (`scripts/characters/states/player_state.gd`):
- `enter()` — ステート開始時処理
- `exit()` — ステート終了時処理
- `process(delta)` — 毎フレーム処理
- `physics_process(delta)` — 物理毎フレーム処理

**ステート一覧と各スクリプト**:

| ステート | ファイル | 遷移先 |
|---------|--------|--------|
| Idle | `idle_state.gd` | Walk, Attack, Jump, Dash, Hit, Dead |
| Walk | `walk_state.gd` | Idle, Attack, Jump, Dash, Hit |
| Attack | `attack_state.gd` | Idle, Combo1→2→3, Grab, Hit |
| Jump | `jump_state.gd` | JumpAttack, Idle（着地） |
| JumpAttack | `jump_attack_state.gd` | Idle（着地） |
| Dash | `dash_state.gd` | DashAttack, Idle |
| DashAttack | `dash_attack_state.gd` | Idle |
| Grab | `grab_state.gd` | GrabAttack, Throw, Idle（解除） |
| GrabAttack | `grab_attack_state.gd` | Grab, Idle |
| Throw | `throw_state.gd` | Idle |
| Special | `special_state.gd` | Idle |
| Hit | `hit_state.gd` | Knockdown, Idle（のけぞり後） |
| Knockdown | `knockdown_state.gd` | GetUp |
| GetUp | `getup_state.gd` | Idle |
| Dead | `dead_state.gd` | （残機処理へ） |

ステートファイルは `scripts/characters/states/` ディレクトリに配置する。

### 2-4. 移動処理の実装

`idle_state.gd` / `walk_state.gd` で以下を実装する。

- 8方向入力の取得（`input_manager.gd` 経由）
- X軸: 横移動（`move_speed` 適用）
- Y軸: 奥行き移動（`move_speed * 0.6` で速度を下げ、奥行き感を出す）
- 向き切り替え（`Sprite.flip_h`）
- 入力なし → Idle、入力あり → Walk の遷移
- `move_and_slide()` による移動処理

### 2-5. 奥行きソート処理の実装

Y座標による描画順序を制御する。

- プレイヤー・敵・オブジェクトの `z_index` をY座標に連動
- `_process()` 内で `z_index = int(global_position.y)` を更新
- または `YSort` 相当のカスタムソートを親ノードに実装

### 2-6. 通常攻撃コンボの実装

`attack_state.gd` で以下を実装する。

- 攻撃ボタン入力でコンボ1段目開始
- アニメーション再生中に再入力 → 次のコンボ段へ遷移
- コンボ受付時間ウィンドウ（アニメーション後半の数フレーム）
- 最終段 or 受付時間切れ → Idle に戻る
- 各段で Hitbox の位置・サイズ・有効フレームが異なる

### 2-7. ジャンプの実装

`jump_state.gd` で以下を実装する。

- ベルトスクロールのジャンプ = **Y軸方向ではなく、見かけ上の高さ（Z軸相当）の変化**
- 内部的に `altitude` 変数を管理し、`Sprite` のオフセットYに反映
- 放物線軌道: `altitude += velocity_z; velocity_z -= gravity`
- `altitude <= 0` で着地 → Idle に遷移
- ジャンプ中も X/Y 方向の移動入力は受け付ける

### 2-8. プレースホルダースプライトの作成

仮のドット絵スプライトを用意する（本格的なアート前の動作確認用）。

- 32×48px 程度のキャラクターサイズ
- 最低限のアニメーション: Idle(2F), Walk(4F), Attack1-3(各3F), Jump(2F), Hit(2F), Down(1F)
- 3キャラ分の色違いで作成（ファイター:青、グラップラー:赤、スピードスター:緑）
- `assets/sprites/characters/` に配置

---

## Phase 3: 当たり判定・ダメージシステム

攻撃が敵に当たり、ダメージを与える仕組みを実装する。

### 3-1. 衝突レイヤー設計

`project.godot` に以下のレイヤーを定義する。

| レイヤー | 番号 | 用途 |
|---------|------|------|
| World | 1 | 地形・壁の衝突 |
| Player | 2 | プレイヤーのボディ |
| Enemy | 3 | 敵のボディ |
| PlayerAttack | 4 | プレイヤーの攻撃判定 |
| EnemyAttack | 5 | 敵の攻撃判定 |
| Item | 6 | アイテム |
| Destructible | 7 | 破壊可能オブジェクト |

### 3-2. Hitbox / Hurtbox コンポーネント実装

汎用的な当たり判定コンポーネントを作成する。

**`scripts/combat/hitbox.gd`** (extends Area2D):
- `damage: int` — ダメージ量
- `knockback_force: Vector2` — のけぞり方向・距離
- `hit_stun_duration: float` — ヒットストップ時間
- `owner_entity: Node` — 攻撃の発生元（自分自身へのヒット防止）
- `activate()` / `deactivate()` — 判定の有効/無効切替
- 奥行き判定: ヒット時に `abs(attacker.y - target.y) <= DEPTH_TOLERANCE` をチェック

**`scripts/combat/hurtbox.gd`** (extends Area2D):
- `on_hit(hitbox: Hitbox)` シグナルを発行
- 無敵時間の管理（被弾後の短時間無敵）

### 3-3. ダメージ処理・コンボカウンター実装

**`scripts/combat/combat_system.gd`**:
- `apply_damage(target, hitbox)` — ダメージ適用メソッド
  - HP 減算
  - のけぞり / ノックダウン判定
  - コンボカウンター加算
- コンボカウンター: 一定時間以内に連続ヒットした数を追跡
- コンボリセット: 攻撃が途切れたらカウンターを 0 に戻す
- ダメージ数値のポップアップ表示（Label + Tween で浮かせて消す）

### 3-4. ヒットストップの実装

ヒット時の一時停止演出を実装する。

- `Engine.time_scale` は使わない（全体に影響するため）
- 代わりに、攻撃側・被弾側の `_process` / `_physics_process` に一時停止フラグを実装
- ヒットストップ中は `AnimatedSprite2D` を一時停止、移動を停止
- 持続: 2〜4フレーム（約33〜66ms）

### 3-5. ヒットエフェクトの作成

- ヒットスパーク: ヒット位置に小さな白い閃光パーティクル
- `GPUParticles2D` またはアニメーション付き `Sprite2D` で実装
- `scripts/combat/hit_effect.gd` でプールして使い回す

---

## Phase 4: 敵AI基本

ザコ敵の共通行動AIと基本的な敵タイプを実装する。

### 4-1. 敵ベースシーン構築

`scenes/characters/enemy/enemy_base.tscn` を作成する。

```
Enemy (CharacterBody2D)
├── Sprite (AnimatedSprite2D)
├── ShadowSprite (Sprite2D)
├── CollisionShape (CollisionShape2D)
├── Hitbox (Area2D)
├── Hurtbox (Area2D)
├── StateMachine (Node)
├── NavigationAgent (Node)            # ターゲットへの経路計算用
└── DetectionArea (Area2D)            # プレイヤー検知範囲
```

### 4-2. 敵ステートマシン実装

敵用のステートマシンを作成する。

| ステート | 説明 |
|---------|------|
| Idle | 出現後の待機 |
| Wander | プレイヤー未検知時のうろつき |
| Chase | プレイヤーに接近 |
| Positioning | 攻撃位置取り（包囲行動） |
| Attack | 攻撃実行 |
| Hit | 被弾のけぞり |
| Knockdown | ダウン |
| GetUp | 起き上がり |
| Dead | 死亡 |

### 4-3. 敵AI基底クラス実装

**`scripts/characters/enemy_ai.gd`**:
- ターゲット（最も近いプレイヤー）の選定
- プレイヤーとの距離・方向の計算
- 攻撃射程に入ったら攻撃ステートへ遷移
- 攻撃後にクールダウン（一定時間攻撃しない）

### 4-4. 同時攻撃制限マネージャー

**`scripts/characters/enemy_attack_manager.gd`** (Autoload or ステージ子ノード):
- `MAX_SIMULTANEOUS_ATTACKERS = 3`
- `request_attack_slot(enemy) -> bool` — 攻撃枠の要求
- `release_attack_slot(enemy)` — 攻撃枠の解放
- 攻撃枠が満杯の場合、敵は Positioning ステートで待機

### 4-5. ザコ敵「チンピラ」の実装

最も基本的な敵として「チンピラ」を完成させる。

- `enemy_base.tscn` を継承
- 近接攻撃（パンチ1〜2段）
- 低HP、通常ののけぞり
- プレースホルダースプライト（赤系の32×48px）

### 4-6. ザコ敵バリエーション実装

チンピラをベースに残り4種を実装する。

**ナイフマン**:
- チンピラの派生。攻撃リーチが長い
- 武器所持フラグあり

**パンクス**:
- Chase ステートの派生で突進攻撃を持つ
- 突進中はスーパーアーマー（のけぞらない）

**火炎瓶兵**:
- 遠距離攻撃：火炎瓶を投射物として発射
- 火炎瓶は `Area2D` の投射物シーンとして分離
- 着弾地点に火炎エリア（数秒間ダメージ判定が残る）

**大男**:
- HP が高い（通常の3倍）
- スーパーアーマー常時（一定ダメージ蓄積でのけぞる）
- 掴み不可フラグ
- 攻撃が遅いが高ダメージ

---

## Phase 5: 掴み・投げ・必殺技・ダッシュ攻撃

プレイヤーの高度なアクションを実装する。

### 5-1. 掴みシステム実装

**`scripts/combat/grab_system.gd`**:
- 掴み判定: 敵に密着（距離 < GRAB_RANGE）かつ正面にいる時、攻撃ボタンで掴み発動
- 掴み中の状態:
  - プレイヤーと敵がロックされ、相対位置を固定
  - 敵は Grabbed ステートに遷移（動けない）
  - 一定時間で自動解除（振りほどき）
- 掴み中の入力分岐:
  - 攻撃ボタン → GrabAttack（膝蹴り等、2〜3回まで）
  - 方向 + 攻撃 → Throw

### 5-2. 投げ実装

`throw_state.gd`:
- 入力方向に敵を投げ飛ばす
- 投げられた敵は放物線軌道で飛ぶ（altitude 処理を流用）
- 飛んでいる最中に他の敵にヒット → 巻き込みダメージ
- 着地時にバウンド1回 → ダウン状態

### 5-3. ダッシュ・ダッシュ攻撃実装

`dash_state.gd`:
- 同方向を素早く2回入力（200ms以内）でダッシュ発動
- ダッシュ中は `dash_speed` で高速移動
- ダッシュ中に攻撃ボタン → DashAttack（突進攻撃）
- ダッシュの持続: 0.5秒、または攻撃ボタンで中断

`dash_attack_state.gd`:
- ダッシュの勢いを利用した攻撃
- のけぞり力が通常攻撃より大きい
- キャラ別に異なるダッシュ攻撃アニメーション

### 5-4. 必殺技実装

`special_state.gd`:
- 攻撃+ジャンプ同時押し（または専用ボタン L / Y）で発動
- HP を `special_hp_cost` 分消費（HP が足りない場合は不発）
- 全身無敵 + 周囲360度に攻撃判定
- 緊急回避として使える（囲まれた時のリカバリー）
- キャラ別に異なるアニメーション・攻撃範囲

---

## Phase 6: ステージシステム

横スクロール制御・敵配置・ステージ進行を実装する。

### 6-1. スクロールカメラ実装

**`scripts/stage/scroll_camera.gd`** (extends Camera2D):
- プレイヤー追従（2P時は2人の中間点を追従）
- 左端制限: プレイヤーがカメラ左端を超えて戻れない（逆スクロール不可）
- 右端制限: スクロールロック中は一定位置で停止
- Y軸移動は緩やかに追従（奥行き方向のカメラ揺れを抑制）
- カメラ移動範囲の上下限設定

### 6-2. スクロールロック / エンカウントシステム

**`scripts/stage/spawn_trigger.gd`** (extends Area2D):
- プレイヤーが特定地点に到達するとトリガー発動
- トリガー発動時:
  1. カメラのスクロールをロック
  2. 敵をスポーン
  3. スポーンした敵が全滅したらロック解除

**`scripts/stage/enemy_spawner.gd`**:
- スポーンデータ（どの敵をどの位置に何体出すか）を保持
- 画面外から歩いて登場 / 画面端に直接配置
- ウェーブ制: 第1ウェーブ全滅 → 第2ウェーブ出現（任意）

### 6-3. ステージマネージャー実装

**`scripts/stage/stage_manager.gd`**:
- ステージの進行状態を管理
- 全エンカウントクリア → ボスエリアへ進行
- ボス撃破 → ステージクリア演出 → 次ステージへ
- タイマー管理（制限時間 90秒 / エリアごとにリセット）

### 6-4. Stage 1「街」の構築

テストステージを本番の Stage 1 として作り込む。

- タイルマップで地面（アスファルト）・建物背景を配置
- 奥行き移動可能範囲（Y軸上下限）の設定
- エンカウントポイント 4〜5 箇所の配置
- 最終エリアにボス戦用の広場
- 背景の多重スクロール（パララックス）: 建物(遅い) / 地面(中間) / 手前の柵(速い)

### 6-5. Stage 2「倉庫」の構築

- コンテナで区切られた狭い通路エリア
- 落とし穴ギミック: `Area2D` で検知し、落ちたキャラは即死 or 大ダメージ
  - 敵も落とし穴に落とせる（投げで押し込む）
- 遠距離敵（火炎瓶兵）が初登場

### 6-6. Stage 3「アジト」の構築

- エレベーター戦闘: 閉鎖空間で連続ウェーブ（エレベーターが停まるたびに敵増援）
- 最終ボス「ボスX」戦用の広いボスルーム
- ステージ全体を通じて敵の出現頻度が高い

---

## Phase 7: アイテム・武器・破壊可能オブジェクト

### 7-1. アイテムシステム実装

**基底アイテムシーン** (`scenes/objects/items/item_base.tscn`):
```
Item (Area2D)
├── Sprite (AnimatedSprite2D)   # アイテム見た目
├── CollisionShape
└── ShadowSprite (Sprite2D)
```

- プレイヤーが重なった状態で攻撃ボタン → アイテム取得
- 取得時のエフェクト（キラリと光る + SE）
- 一定時間で点滅 → 消滅

**回復アイテム**:
- 肉（小）: HP 30% 回復
- 肉（大）: HP 全回復
- 1UP: 残機 +1

**スコアアイテム**:
- 宝石（数種類、スコア値が異なる）

### 7-2. 武器システム実装

**武器データリソース** (`scripts/resources/weapon_data.gd`):
- `weapon_name`, `damage_multiplier`, `durability`, `attack_speed`, `range`, `is_throwable`

**武器の動作**:
- フィールドに落ちている武器を攻撃ボタンで拾う
- 武器所持中は通常攻撃が武器攻撃に変化
- 攻撃ごとに耐久値 -1。耐久 0 で武器破壊
- 武器ごとにアニメーション・Hitbox サイズが異なる
- 投げ専用武器（木箱）: 拾った瞬間に投げモーションへ移行

### 7-3. 破壊可能オブジェクト実装

**ドラム缶** (`scenes/objects/destructibles/barrel.tscn`):
- HP を持ち、攻撃でダメージ
- 破壊時にアイテムをドロップ（ドロップテーブルで管理）
- 破壊エフェクト（破片が飛ぶアニメーション）

**木箱** (`scenes/objects/destructibles/crate.tscn`):
- 1 回の攻撃で破壊
- 武器アイテムをドロップしやすい

---

## Phase 8: ボス敵実装

### 8-1. ボス基底クラス

通常の敵AIを拡張した **ボス用AI基底** を作成する。

- 複数の攻撃パターンをフェーズ制で管理
- HP しきい値で行動パターン変化（怒りモード等）
- ボス用 UI: HPバーを画面下部に大きく表示
- 登場演出・撃破演出のフック

### 8-2. Stage 1 ボス「バウンサー」

- 入門ボス。パターンが読みやすい
- 攻撃パターン:
  - 連続パンチ（3連打 → 隙）
  - タックル（溜め動作 → 直線突進）
  - つかみかかり（プレイヤー接近時）
- HP 50% 以下で攻撃速度アップ

### 8-3. Stage 2 ボス「クノイチ」

- 回避重視の戦闘
- 攻撃パターン:
  - 高速接近 → 3連斬り → 離脱
  - 手裏剣（遠距離 / 3方向拡散）
  - 分身（残像を出して位置を攪乱、本体は背後から攻撃）
- HP 30% 以下で分身が増加

### 8-4. Stage 3 ボス「ボスX」

- 最終ボス。2フェーズ制
- **第1形態**（HP 100%〜50%）:
  - 格闘攻撃（多段コンボ）
  - 掴み → 投げ（プレイヤーを投げる）
  - ジャンプ攻撃（着地時に衝撃波）
- **第2形態**（HP 50% 以下）:
  - 武器（日本刀）を使用
  - 攻撃リーチ・ダメージ増加
  - 居合い斬り（広範囲 / 溜め動作あり）
  - 移動速度アップ

---

## Phase 9: 2人プレイ対応

### 9-1. マルチプレイヤー管理

`game_manager.gd` を拡張:
- `player_count: int` （1 or 2）
- タイトル画面で「2P START」選択時に `player_count = 2`
- プレイヤーインスタンスを `player_count` 分生成
- 各プレイヤーに `player_index` (0 or 1) を割り当て

### 9-2. 2P入力の分離

`input_manager.gd` を拡張:
- `player_index` を受け取り、対応する `p1_*` / `p2_*` アクションを返す
- 2P はゲームパッド Device 1 のみ（キーボードは 1P 専用）
- デバイス接続/切断の検知とメッセージ表示

### 9-3. カメラの2P対応

`scroll_camera.gd` を拡張:
- 2人の中間点を追従ターゲットに変更
- 2人が離れすぎた場合の制限（画面端で移動制限）
- 1人が死亡した場合は生存プレイヤーのみ追従

### 9-4. 敵AIの2P対応

- ターゲット選択: 最も近いプレイヤーをターゲットに
- 包囲行動: 2人のプレイヤーを挟むように分散
- 2P プレイ時は敵出現数を 1.5 倍に増加（`enemy_spawner.gd` のスポーンデータに倍率パラメータ追加）

### 9-5. 協力コンボ

- 片方のプレイヤーが敵を掴んでいる時、もう一方が攻撃可能
- フレンドリーファイアは無し（プレイヤー攻撃の衝突レイヤーからプレイヤーの Hurtbox を除外）

---

## Phase 10: UI・スコア・ゲームフロー

### 10-1. HUD 実装

`scenes/ui/hud.tscn` (CanvasLayer):
- 1P/2P のキャラ顔アイコン、HP バー、残機数
- スコア表示、ハイスコア表示
- 残り時間表示
- ボス戦時にボス HP バーを追加表示

### 10-2. タイトル画面

`scenes/main/title_screen.tscn`:
- ゲームロゴ（プレースホルダー）
- メニュー: 1P START / 2P START / OPTIONS
- BGM 再生
- 選択時の SE・アニメーション

### 10-3. キャラクター選択画面

`scenes/main/character_select.tscn`:
- 3キャラクターの立ち絵（プレースホルダー）とステータス比較
- 1P/2P 個別に選択
- 選択確定 → ゲーム開始

### 10-4. ポーズメニュー

`scenes/ui/pause_menu.tscn`:
- Escape / Start でトグル
- RESUME / RESTART / QUIT TO TITLE
- ポーズ中は `get_tree().paused = true`

### 10-5. ステージクリア・リザルト画面

`scenes/ui/result_screen.tscn`:
- 敵撃破数、コンボ最大数、タイムボーナス、ノーダメージボーナス
- スコア加算アニメーション
- 一定時間後に次ステージへ自動遷移

### 10-6. ゲームオーバー画面

`scenes/main/game_over.tscn`:
- CONTINUE（残りコンティニュー数表示）/ QUIT TO TITLE
- コンティニュー回数: 最大3回
- カウントダウンタイマー（10秒以内に選択しないと QUIT）

### 10-7. エンディング

- スタッフロール（テキストスクロール）
- ハイスコア表示
- タイトルに戻る

### 10-8. スコアシステム統合

`score_manager.gd` を完成させる:
- 敵撃破スコア、コンボボーナス、アイテムスコアの加算
- ステージクリア時のタイムボーナス、ノーダメージボーナス計算
- 一定スコア（50000点）ごとに 1UP
- ハイスコアのローカル保存（`ConfigFile` で `user://highscore.cfg` に保存）

---

## Phase 11: サウンド・演出

### 11-1. AudioManager 実装

`audio_manager.gd` を完成させる:
- BGM: `AudioStreamPlayer` で再生（1トラック、クロスフェード対応）
- SE: `AudioStreamPlayer` のプール（同時再生 8ch）
- 音量設定（BGM / SE 個別）

### 11-2. SE の組み込み

各アクションに SE を連携する。

| タイミング | SE |
|-----------|-----|
| パンチヒット | punch_hit.wav |
| キックヒット | kick_hit.wav |
| 武器ヒット | weapon_hit.wav |
| 空振り | swing_miss.wav |
| ジャンプ | jump.wav |
| 着地 | land.wav |
| ダッシュ | dash.wav |
| 投げ | throw.wav |
| 必殺技 | special.wav |
| アイテム取得 | item_pickup.wav |
| 敵撃破 | enemy_defeat.wav |
| UI 決定 | ui_confirm.wav |
| UI カーソル移動 | ui_cursor.wav |

### 11-3. BGM の組み込み

| シーン | BGM |
|-------|-----|
| タイトル | title_bgm |
| Stage 1 | stage1_bgm |
| Stage 2 | stage2_bgm |
| Stage 3 | stage3_bgm |
| ボス戦 | boss_bgm |
| ゲームオーバー | gameover_bgm |
| エンディング | ending_bgm |

- ステージ開始時に BGM を再生
- ボスエリア突入時にボス BGM に切替
- プレースホルダー音源は無料素材または無音ファイル

### 11-4. 画面演出

- **ヒットストップ**: Phase 3 で実装済み
- **画面揺れ**: 強攻撃ヒット時・ボスの大技時にカメラシェイク
  - `scroll_camera.gd` に `shake(intensity, duration)` を追加
- **フラッシュ**: 必殺技発動時に画面全体を白く一瞬フラッシュ
- **スローモーション**: 最終ボス撃破時の最後の一撃で短時間スロー

### 11-5. パーティクル・エフェクト

- ヒットスパーク（Phase 3 で基本実装済み）のブラッシュアップ
- ダッシュ時の砂埃
- 必殺技のオーラエフェクト
- 敵撃破時の爆発・消滅エフェクト
- 火炎瓶の炎エフェクト

---

## Phase 12: 調整・デバッグ・ポリッシュ

### 12-1. ゲームバランス調整

- キャラクターパラメータの調整（HP、攻撃力、速度）
- 敵のHP・攻撃力・出現数の調整
- ボスの難易度調整（攻撃頻度、隙の長さ）
- コンティニュー回数・制限時間の調整

### 12-2. デバッグツール

開発用のデバッグ機能を実装する（リリース時は無効化）。

- 無敵モード ON/OFF（F1）
- ステージセレクト（F2）
- 敵全滅（F3）
- HP/スコアの表示（F4）
- ヒットボックス可視化（F5）
- フレームレート表示

### 12-3. パフォーマンス最適化

- オブジェクトプーリング（敵・投射物・エフェクト）
- 画面外の敵・オブジェクトの処理停止
- スプライトアトラスの最適化

### 12-4. 最終テスト・ポリッシュ

- 全ステージの通しプレイテスト
- 2Pプレイのテスト
- エッジケースの修正（同時被弾、画面端処理等）
- ゲームオーバー → コンティニュー → クリアの全フロー確認

---

## 依存関係図

```
Phase 1  ─────────────────────────────────────────────┐
   │                                                   │
Phase 2 (プレイヤー)                                    │
   │                                                   │
Phase 3 (当たり判定) ──┐                                │
   │                  │                                │
Phase 4 (敵AI) ←──────┘                                │
   │                                                   │
Phase 5 (掴み・必殺技等) ← Phase 2 + Phase 3            │
   │                                                   │
Phase 6 (ステージ) ← Phase 4                            │
   │                                                   │
Phase 7 (アイテム) ← Phase 3                            │
   │                                                   │
Phase 8 (ボス) ← Phase 4 + Phase 6                     │
   │                                                   │
Phase 9 (2P対応) ← Phase 1〜8                           │
   │                                                   │
Phase 10 (UI・フロー) ← 全Phase                         │
   │                                                   │
Phase 11 (サウンド・演出) ← 全Phase                      │
   │                                                   │
Phase 12 (調整) ← 全Phase                        ──────┘
```

> **Note**: Phase 2〜5 はプレイヤー・戦闘の中核であり、ここを先に固めることで
> 以降の Phase がスムーズに進む。Phase 6〜8 はコンテンツ作成が中心のため並行作業も可能。
