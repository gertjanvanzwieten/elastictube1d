#ifndef FLUID_NL_H_
#define FLUID_NL_H_

#define PI 3.14159265359

int fluid_nl(double* crossSectionLength,
             double* crossSectionLength_n,
             double* velocity,
             double* velocity_n,
             double* pressure,
             double* pressure_n,
             double* pressure_old,
             int t,
             int N,
             double kappa,
             double tau,
             double gamma);

int linsolve(int n,
             double** A,
             double* b,
             double* x);

#endif
