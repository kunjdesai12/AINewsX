from pipeline import run_full_pipeline
import json

def run_interactive():
    while True:
        user_input = input("\n📰 Enter news text (or type 'exit' to quit): ")
        if user_input.lower() == "exit":
            break

        print("\n🔍 Checking news...")
        result = run_full_pipeline(user_input)

        # Pretty print results
        print("\n--- ML Model ---")
        print(f"Prediction: {result['ml']['label']}")
        print(f"Probabilities: {result['ml']['probabilities']}")

        print("\n--- Fact Checker ---")
        if result["fact"]["found"]:
            for match in result["fact"]["top_matches"]:
                print(f"- {match['title']} ({match['source']}) | Sim: {match['similarity']:.2f}")
        else:
            print("No supporting articles found ❌")

        print("\n--- Final Verdict ---")
        print(f"{result['final']['final_verdict']} → {result['final']['reason']}")
        print("-----------------------------")

if __name__ == "__main__":
    run_interactive()
