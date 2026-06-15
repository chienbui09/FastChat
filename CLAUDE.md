# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FastChat is a distributed multi-model LLM serving platform with OpenAI-compatible APIs, a web UI (Gradio), and fine-tuning/evaluation tooling. The package name on PyPI is `fschat`.

## Installation

```bash
pip3 install -e ".[model_worker,webui]"
```

Optional dependency groups: `model_worker`, `webui`, `train`, `llm_judge`, `dev`.

## Common Commands

### Formatting & Linting

```bash
./format.sh                             # Format changed files (black + pylint)
./format.sh --all                       # Format all files
./format.sh --files file1.py file2.py  # Specific files
```

CI checks: `black==23.3.0` (formatting), `pylint==2.8.2` (Google style via `.pylintrc`).

### Running Tests

```bash
python3 tests/test_cli.py              # CLI inference test
python3 tests/launch_openai_api_test_server.py && python3 tests/test_openai_api.py
python3 tests/test_openai_vision_api.py
python3 tests/load_test.py
```

### Starting Services

```bash
# Controller (manages workers)
python3 -m fastchat.serve.controller --host 0.0.0.0 --port 21001

# Model worker (registers with controller, runs inference)
python3 -m fastchat.serve.model_worker --model-path lmsys/vicuna-7b-v1.5

# OpenAI-compatible REST API
python3 -m fastchat.serve.openai_api_server --host 0.0.0.0 --port 8000

# Gradio web UI (single model)
python3 -m fastchat.serve.gradio_web_server

# Gradio arena (multi-model side-by-side)
python3 -m fastchat.serve.gradio_web_server_multi

# CLI chat
python3 -m fastchat.serve.cli --model-path lmsys/vicuna-7b-v1.5

# Launch all services together
python3 -m fastchat.serve.launch_all_serve
```

## Architecture

FastChat runs as a set of cooperating processes:

```
Client (Gradio UI / CLI / REST API client)
         ↓
  OpenAI API Server (port 8000)   ←→   Gradio Web Server (port 7860)
         ↓                                        ↓
              Controller (port 21001)
         [Registers workers, dispatches requests]
         ↓ (LOTTERY or SHORTEST_QUEUE dispatch)
  Model Workers (port 31000+)
  [HuggingFace | vLLM | LightLLM | MLX | SGLang | DashInfer | HF API]
```

- **Controller** (`fastchat/serve/controller.py`): Tracks live workers via heartbeats. Two dispatch strategies: `lottery` (weighted random) and `shortest_queue`.
- **Model Workers**: Each worker loads one model, registers with the controller, and serves generation requests. `base_model_worker.py` is the base class; specialized workers (e.g., `vllm_worker.py`) extend it.
- **OpenAI API Server** (`fastchat/serve/openai_api_server.py`): FastAPI app implementing `/v1/chat/completions`, `/v1/completions`, `/v1/embeddings`, `/v1/models`. Forwards to workers via the controller.
- **Gradio Web Server** (`fastchat/serve/gradio_web_server.py`): Single-model UI. `gradio_web_server_multi.py` is the arena (battle) variant.

## Key Source Files

| File | Purpose |
|------|---------|
| `fastchat/conversation.py` | Conversation templates — `SeparatorStyle`, `Conversation`, and 30+ model-specific templates |
| `fastchat/model/model_adapter.py` | Model loading logic; maps model names to adapters and conversation templates |
| `fastchat/constants.py` | Global constants (error messages, default ports, etc.) |
| `fastchat/protocol/openai_api_protocol.py` | Pydantic models for OpenAI-compatible request/response types |
| `fastchat/serve/base_model_worker.py` | Abstract base for all model workers |
| `fastchat/utils.py` | Shared utilities (logging, streaming, etc.) |

## Adding Model Support

To add a new model, register an adapter in `fastchat/model/model_adapter.py` and add a `Conversation` template in `fastchat/conversation.py`. The adapter maps model name patterns to loading logic and the right conversation template.

## Fine-tuning

Training scripts are in `fastchat/train/`. The main entry points are:
- `train.py` — full-parameter SFT
- `train_lora.py` — LoRA fine-tuning
- Shell scripts in `scripts/` (e.g., `train_vicuna_7b.sh`)

Requires the `train` optional dependencies group; uses DeepSpeed configs from `playground/deepspeed_config_s3.json`.

## Evaluation (LLM Judge / MT-Bench)

`fastchat/llm_judge/` contains the MT-Bench evaluation framework. Uses the `llm_judge` optional dependency group.

## Environment & Configuration

- Default ports: Controller `21001`, Model Worker `31000`, OpenAI API `8000`, Gradio `7860`
- Model cache: `~/.cache/huggingface/hub/` (or ModelScope via `FASTCHAT_USE_MODELSCOPE=True`)
- Supported devices: `cuda`, `cpu`, `mps` (Apple Silicon), `xpu` (Intel), `npu` (Ascend)
- Gradio theme: `theme.json`
