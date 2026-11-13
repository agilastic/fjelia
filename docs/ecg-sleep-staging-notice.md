# ECG sleep-staging model notice

Model: `primary_model_only_ecg`, checkpoint `epoch_0369_kappa_0.721.pt`.

Source project: <https://github.com/adammj/ecg-sleep-staging>
Upstream revision used: `cf259ebe3004dc68709c853b38d41be88be31a79`.
Copyright: Adam Jones, 2024. The upstream source and checkpoint are licensed
under GNU AGPL version 3 or later. The license text is in
`assets/licenses/ecg-sleep-staging.txt`.

Fjelia runs the exported ONNX model at `assets/models/ecg_sleep_staging.onnx`
using a Dart implementation. The input preparation is an app-side approximation
of the upstream pipeline and has not been validated against PSG for Polar H10
recordings. The model predicts Wake, N1, N2, N3 and REM; Fjelia groups N1 and N2
as Light sleep. This experimental feature is not a medical measurement.
