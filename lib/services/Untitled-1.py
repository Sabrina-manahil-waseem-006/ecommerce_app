print("SOLUTION BY NEWTON–RAPHSON METHOD")

# Parameters
q_in = 1000          # W/m^2
h = 25               # W/m^2.K
T_inf = 300          # K
epsilon = 0.85
sigma = 5.670374419e-8  # W/m^2.K^4

# Nonlinear function
def f(Ts):
    return h*(Ts - T_inf) + epsilon*sigma*(Ts**4 - T_inf**4) - q_in

# Derivative of the function
def f_prime(Ts):
    return h + 4 * epsilon * sigma * Ts**3

# Newton–Raphson Implementation
def newton_method(T0, tol=1e-6, max_iter=100):
    print(f"{'Iter':<6}{'Tn (K)':<15}{'T_next (K)':<15}{'f(T_next)':<15}")
    print("-"*60)

    Tn = T0

    for i in range(max_iter):
        f_Tn = f(Tn)
        fp_Tn = f_prime(Tn)

        if fp_Tn == 0:
            print("Derivative is zero — method failed.")
            return None

        # Newton update
        T_next = Tn - f_Tn / fp_Tn
        f_next = f(T_next)

        print(f"{i:<6}{Tn:<15.6f}{T_next:<15.6f}{f_next:<15.6f}")

        # Convergence check
        if abs(T_next - Tn) < tol:
            print(f"\nConverged in {i+1} iterations")
            return T_next

        Tn = T_next

    print("Did not converge within maximum iterations")
    return None

# Initial guess
T0 = 350  # K

Ts_root = newton_method(T0)
print(f"\nSurface temperature Ts = {Ts_root} K")
