# Optional local Qwen models

Select **Settings → AI & more → Qwen3.5 (local)**, choose **2B or 4B**, and
download that model. Providers appear in this order: Free AI, Apple Intelligence,
Qwen, then the providers that require a personal API key. The initial Qwen
choice remains 2B.
The same provider then handles coach chat and AI briefings without an API key.
Each model's download can be cancelled, resumed and deleted from this panel.
Switching models preserves downloaded files and checks the selected model's
own readiness. Having 2B installed never activates a missing 4B model. Changing
the model unloads the previous native request before activating the selection.

## Model and storage

| Model | Download including tokenizer and config | Device RAM policy |
| --- | --- | --- |
| [Qwen3.5-2B MLX 4-bit](https://huggingface.co/mlx-community/Qwen3.5-2B-MLX-4bit) | 1,749,079,691 bytes, about **1749 MB / 1.75 GB** | At least 4 GB |
| [Qwen3.5-4B MLX 4-bit](https://huggingface.co/mlx-community/Qwen3.5-4B-MLX-4bit) | 3,061,129,077 bytes, about **3061 MB / 3.06 GB** | **iPhone 18 or newer**, at least 8 GB |

Sizes are decimal disk sizes, not peak RAM use. Installing both needs about
4.81 GB. The model catalog pins 2B to revision
`93760be4f1f69842a46bc13dbdc0f19e291392a3` and 4B to
`32f3e8ecf65426fc3306969496342d504bfa13f3`. The 4B weights alone are
3,034,300,695 bytes, with SHA-256
`5fb9acd0246866381cf8c5c354c6db1019f6498eec4ccb4f5edcc71ffeacb2db`.

- The app includes the MLX runtime and license notices. The weights are an
  optional download and are not included in the app bundle.
- Files live in Application Support under `local_models/qwen35_2b_mlx4` and
  `local_models/qwen35_4b_mlx4`, excluded from iCloud backup. Existing 2B
  installations keep their original directory and marker. Partial downloads use `.part` files. Resuming
  uses HTTP Range; servers ignoring Range cause a clean restart of that file.
- The pinned download manifest checks every file's size and SHA-256 for the
  weights and tokenizer. An installation marker is committed only after
  validation. Downloads survive app restarts; background download execution is
  not implemented.

Inference opens a local directory only. Selecting Qwen does not send prompts or
health data to a cloud provider, does not use an Apple briefing override and
does not fall back to cloud inference on failure. Downloading weights contacts
Hugging Face; opening the model details link opens its website.

## Device requirements

The iOS app now requires **iOS 17 or later** because of MLX Swift. This still
allows iPhone 11 to run the rest of Fjelia.

Local MLX additionally checks the **Apple7 Metal GPU family** (A14 or newer on
iPhone). Availability and inference both enforce the selected model's RAM
requirement: at least 3.5 billion physical bytes for 2B (4 GB class devices) or
7.5 billion for 4B (8 GB class devices). These are Fjelia's conservative device
eligibility thresholds, not measured peak RAM guarantees. At the user's request,
4B is additionally restricted to **iPhone 18 and later**. The native code checks
the hardware identifier during availability and generation, including the model
ID in an existing installation marker. iPhone 17 Pro (`iPhone18,1`) is an older
device for this rule; the iPhone 18 hardware family starts at `iPhone19,x`.
The 4B choice is disabled on older iPhones, while existing 4B downloads remain
deletable. **iPhone 17 Pro supports 2B, not 4B under this policy.**
**iPhone 11 cannot use this MLX backend**; supporting local inference
there would require a separate backend such as llama.cpp. The iOS simulator and
other app platforms currently report the provider as unavailable. A compatible
GPU alone does not establish that a low-memory phone can sustain this model;
peak RAM, speed and thermals still need physical-device testing.

For an iPhone 11 prototype, [Qwen3.5-0.8B GGUF Q4_K_M](https://huggingface.co/bartowski/Qwen_Qwen3.5-0.8B-GGUF)
(about 580 MB for that conversion) is a candidate for a separate llama.cpp
backend, which is not implemented here. It has not been tested on iPhone 11.
An 0.8B model is a candidate for short explanations of facts already computed
by Fjelia; it should not be assumed reliable for open-ended sports-science
analysis. The existing rule-based summaries remain available on older phones.

The runtime processes one request at a time, cancels on loss of foreground
activity and releases the model after each reply. It limits the Metal cache to
32 MB. Model requests are limited to 8192 input plus output tokens, allowing
room for message framing; output is capped at 512 tokens for chat and 160 for
briefings. Thinking output is disabled. Fjelia's existing fact selection,
missing-data rules, recovery rules and app-language instructions are reused.

## Daily briefing and planned sessions

Today's pending plan sessions stay in the briefing context even after another
activity has been recorded today. Completed/skipped plan sessions are excluded
by the query, and Garmin copies are not added to the Fjelia plan's count.
The context explicitly distinguishes scheduled sessions from alternatives.

When there are pending sessions, the model receives their exact count and a
localized sentence stating it. An answer omitting that sentence uses the app's
own localized summary, including the same correct count. This is necessary
because the actual 2B model still omitted or denied planned training in the
synthetic regression example, despite correct input. Briefing cache version v5
discards replies generated with the earlier prompt.

The regression was checked with 127 focused Flutter tests and actual offline
2B inference on synthetic data. On a physical iPhone 17 Pro, the selected 2B
provider, two pending sessions and inclusion of the count in the displayed
briefing were verified through the Dart VM service.

Chat and all four daily briefings write an `[AiGeneration]` line to the console
and in-app debug log for each request. It identifies the task, provider,
service (MLX, FoundationModels or API host), selected model and attempt number.
Apple's model is labelled `on-device`, since its version is managed by the OS.
Cloud responses that report a different model log the resolved model too.
Briefing fallbacks identify Fjelia's own summary as `model=none` and explain
why the model reply was replaced.

## Chat facts and the complete race calendar

The local request reserves one compact calendar containing every supplied race
goal, with its date, priority, sport, distance and target time. Optional detailed
context is fitted afterwards. Goals cannot fall out individually and leave only
the primary race. An answer to a question about goals that omits calendar
entries is supplemented with the app's complete list. The context cache also checks the goal-set revision and the
profile's goal text, so edits are visible on the next chat request.

Sleep duration is explicitly distinguished from sleep shortfall, and current TSB
from a weekly CTL change. Chat analysis uses the chart's current CTL/ATL/TSB when
the caller did not supply a monitor. Blood pressure cannot establish a training
phase.

An offline 2B test with synthetic screenshot-like data correctly compared stress
20 with average 24 and sleep duration 7 h with need 8 h, but then called energy
34 a glucose reading. This reply is rejected by the local chat checks. They
also catch the observed reversed stress comparison, incorrect numeric sleep
shortfall, TSB described as a weekly rate and blood pressure used to assert a
training phase. A rejected reply is replaced by
Fjelia's labelled, localised data summary and full supplied calendar; the debug
log identifies this as `model=none` and records the reason.

These checks cover specific observable errors, not arbitrary factual or
scientific claims. They do not make the 2B model a reliable scientific verifier.

## Build and verification

The local Swift package is `ios/FjeliaMLX`; `mlx-swift-lm` is pinned to 2.31.3,
with transitive versions recorded in the workspace and package lockfiles.
Model and runtime licenses are included in the app's Licenses page.

Before a direct Flutter or Xcode build on a new Mac, enable the reviewed,
pinned MLX build plugin once:

```bash
python3 scripts/trust-mlx-plugin.py
```

The iOS build and development scripts run this automatically. This records
only `mlx-swift` 0.31.6's `CudaBuild` plugin at revision
`0bb916c67f4b9e5c682cbe02a42c701c93ab5021` in the current user's Xcode plugin
trust file, preserving other entries. A changed MLX pin requires another code
review. The plugin returns immediately on Apple platforms; its CUDA commands
are Linux-only. Alternatively, open `ios/Runner.xcworkspace` in Xcode and
enable `CudaBuild` when prompted by the first build.

Install Xcode's Metal toolchain if needed:

```bash
xcodebuild -downloadComponent MetalToolchain
```

The iOS scripts now run `scripts/ensure-metal-toolchain.sh` before Flutter.
It checks the compiler itself with `xcrun metal --version`, installs or
re-registers a missing component, then checks again. Cached builds can succeed
without a usable compiler while Xcode's debug launch still demands the
component, so build success alone is not used as the readiness check.
After installing or re-registering the component while Xcode is open, restart
Xcode once to refresh its UI's cached component status.

Unsigned device build (use writable cache directories appropriate to the host):

```bash
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/fjelia-mlx-build \
  -clonedSourcePackagesDirPath /tmp/fjelia-mlx-sourcepackages \
  CODE_SIGNING_ALLOWED=NO build
```

After the one-time plugin setup, ordinary `flutter run` and
`flutter build ios --debug` also work without a validation bypass.

Focused Flutter checks:

```bash
flutter test --no-pub \
  test/screens/local_model_settings_test.dart \
  test/services/local_model_service_test.dart \
  test/services/local_coach_test.dart \
  test/services/ai_coach_settings_test.dart \
  test/services/apple_coach_request_test.dart \
  test/services/coach_situations_test.dart \
  test/screens/ai_coach_error_test.dart \
  test/screens/briefing_card_test.dart test/l10n
```

The native integration test is opt-in and makes no downloads. Supply a local
copy of the pinned snapshot with an `installed.json` marker containing
`{"model":"mlx-community/Qwen3.5-2B-MLX-4bit","revision":"93760be4f1f69842a46bc13dbdc0f19e291392a3"}`.
For 4B, use `{"model":"mlx-community/Qwen3.5-4B-MLX-4bit","revision":"32f3e8ecf65426fc3306969496342d504bfa13f3"}`
and point the same test at the 4B directory.
On an Apple Silicon Mac:

```bash
cd ios/FjeliaMLX
TEST_RUNNER_FJELIA_LOCAL_MODEL_TEST_DIR=/absolute/path/to/model \
  xcodebuild -scheme FjeliaMLX -destination 'platform=macOS' \
  -derivedDataPath /tmp/fjelia-mlx-native-test \
  -clonedSourcePackagesDirPath /tmp/fjelia-mlx-sourcepackages test
```

On 2026-10-29, the unsigned iOS build, 85 focused Flutter tests and native
inference with the actual 2B and 4B weights in all ten app languages passed. The
native tests also checked the physical-memory guard and hardware-family cutoff.
Eight build-helper tests cover scoped plugin trust and Metal toolchain checks. After the
scoped plugin setup, the signed `flutter build ios --debug --no-pub` build also
passed with plugin validation enabled, along with four tests for pin checks
and preservation of existing plugin trust entries. The native
test checks nonempty replies and disabled thinking; **it is not a language or
sport-science benchmark**. The synthetic training example still elicited
unsupported interpretations and weak wording in some languages, especially
Finnish even with 4B. No superiority
over Apple Intelligence has been established, and inference performance on a
physical iPhone has not yet been measured. The model remains an optional
provider selection.

The user-supplied [local-ai reference app](https://github.com/carolinacherry/local-ai)
was useful for cross-checking the model choice and MLX setup. Fjelia retains its
own download, settings, privacy and coach-context implementation.
