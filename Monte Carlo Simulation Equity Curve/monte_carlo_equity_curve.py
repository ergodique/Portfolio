import numpy as np
import matplotlib.pyplot as plt

def calculate_drawdown(balances):
    peak = balances[0]
    drawdowns = []
    for balance in balances:
        if balance > peak:
            peak = balance
        drawdown = (peak - balance) / peak
        drawdowns.append(drawdown)
    return drawdowns

def monte_carlo_simulation(win_rate, reward_to_risk, risk_per_trade, num_simulations, num_trades):
    all_balances = []
    final_balances = []
    max_drawdowns = []

    start_balance = 1000

    for _ in range(num_simulations):
        balance = start_balance  # Starting with a balance of 1 for simplicity
        balances = [balance]
        
        for _ in range(num_trades):
            if np.random.rand() < win_rate:
                # Win trade
                balance += balance * risk_per_trade * reward_to_risk
            else:
                # Lose trade
                balance -= balance * risk_per_trade

            balances.append(balance)
        
        all_balances.append(balances)
        final_balances.append(balance)
        max_drawdowns.append(max(calculate_drawdown(balances)))

    # Plot the results
    plt.figure(figsize=(12, 8))
    for balances in all_balances[:100]:
        plt.plot(balances, color='blue', alpha=0.1)
    
    plt.plot(all_balances[np.argmax(final_balances)], color='green', linewidth=2, label='Maximum Equity Curve')
    plt.plot(all_balances[np.argmin(final_balances)], color='red', linewidth=2, label='Minimum Equity Curve')
    plt.title('Monte Carlo Simulation of Trading System')
    plt.xlabel('Trade Number')
    plt.ylabel('Account Balance')
    plt.legend()
    plt.show()

    # Statistical summary of final balances and drawdowns
    max_drawdown_worst_case = max(max_drawdowns)
    mean_drawdown = np.mean(max_drawdowns)
    drawdown_99_percentile = np.percentile(max_drawdowns, 99)
    

    print(f'Starting Balance: {start_balance:.2f}')
    print(f'Mean Final Balance: {np.mean(final_balances):.2f}')
    print(f'Standard Deviation: {np.std(final_balances):.2f}')
    print(f'Minimum Final Balance: {np.min(final_balances):.2f}')
    print(f'Maximum Final Balance: {np.max(final_balances):.2f}')
    print(f'Maximum Drawdown of Worst Case: {max_drawdown_worst_case:.2f}')
    print(f'Mean Maximum Drawdown: {mean_drawdown:.2f}')
    print(f'99th Percentile Drawdown: {drawdown_99_percentile:.2f}')

# Example usage
win_rate = 0.9  # put win rate here
reward_to_risk = 0.3  # Reward to risk ratio 
risk_per_trade = 0.02  # Risking % of the trade
num_simulations = 10000  # Run X number of simulations
num_trades = 252  # Each simulation runs for X trades

print(f'Win Rate: {win_rate:.2f}')
print(f'R-Ratio: {reward_to_risk:.2f}')
print(f'% Risk per Trade: {risk_per_trade:.2f}')
print(f'# of Simulations: {num_simulations:.2f}')
print(f'# of Trades: {num_trades:.2f}')

monte_carlo_simulation(win_rate, reward_to_risk, risk_per_trade, num_simulations, num_trades)
