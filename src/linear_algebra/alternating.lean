/-
Copyright (c) 2020 Zhangir Azerbayev. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Eric Wieser, Zhangir Azerbayev
-/

import linear_algebra.multilinear
import group_theory.perm.sign
import data.equiv.fin
import linear_algebra.tensor_product
import ring_theory.algebra_tower
import group_theory.quotient_group

/-!
# Alternating Maps

We construct the bundled function `alternating_map`, which extends `multilinear_map` with all the
arguments of the same type.

## Main definitions
* `alternating_map R M N ι` is the space of `R`-linear alternating maps from `ι → M` to `N`.
* `f.map_eq_zero_of_eq` expresses that `f` is zero when two inputs are equal.
* `f.map_swap` expresses that `f` is negated when two inputs are swapped.
* `f.map_perm` expresses how `f` varies by a sign change under a permutation of its inputs.
* An `add_comm_monoid`, `add_comm_group`, and `semimodule` structure over `alternating_map`s that
  matches the definitions over `multilinear_map`s.

## Implementation notes
`alternating_map` is defined in terms of `map_eq_zero_of_eq`, as this is easier to work with than
using `map_swap` as a definition, and does not require `has_neg N`.
-/

-- semiring / add_comm_monoid
variables {R : Type*} [semiring R]
variables {M : Type*} [add_comm_monoid M] [semimodule R M]
variables {N : Type*} [add_comm_monoid N] [semimodule R N]

-- semiring / add_comm_group
variables {L : Type*} [add_comm_group L] [semimodule R L]

-- ring / add_comm_group
variables {R' : Type*} [ring R']
variables {M' : Type*} [add_comm_group M'] [semimodule R' M']
variables {N' : Type*} [add_comm_group N'] [semimodule R' N']

variables {ι : Type*} [decidable_eq ι]

set_option old_structure_cmd true

section
variables (R M N ι)
/--
An alternating map is a multilinear map that vanishes when two of its arguments are equal.
-/
structure alternating_map extends multilinear_map R (λ i : ι, M) N :=
(map_eq_zero_of_eq' : ∀ (v : ι → M) (i j : ι) (h : v i = v j) (hij : i ≠ j), to_fun v = 0)
end

/-- The multilinear map associated to an alternating map -/
add_decl_doc alternating_map.to_multilinear_map

namespace alternating_map

variables (f f' : alternating_map R M N ι)
variables (g' : alternating_map R' M' N' ι)
variables (v : ι → M) (v' : ι → M')
open function

/-! Basic coercion simp lemmas, largely copied from `ring_hom` and `multilinear_map` -/
section coercions

instance : has_coe_to_fun (alternating_map R M N ι) := ⟨_, λ x, x.to_fun⟩

initialize_simps_projections alternating_map (to_fun → apply)

@[simp] lemma to_fun_eq_coe : f.to_fun = f := rfl

@[simp] lemma coe_mk (f : (ι → M) → N) (h₁ h₂ h₃) : ⇑(⟨f, h₁, h₂, h₃⟩ :
  alternating_map R M N ι) = f := rfl

theorem congr_fun {f g : alternating_map R M N ι} (h : f = g) (x : ι → M) : f x = g x :=
congr_arg (λ h : alternating_map R M N ι, h x) h

theorem congr_arg (f : alternating_map R M N ι) {x y : ι → M} (h : x = y) : f x = f y :=
congr_arg (λ x : ι → M, f x) h

theorem coe_inj ⦃f g : alternating_map R M N ι⦄ (h : ⇑f = g) : f = g :=
by { cases f, cases g, cases h, refl }

@[ext] theorem ext {f f' : alternating_map R M N ι} (H : ∀ x, f x = f' x) : f = f' :=
coe_inj (funext H)

theorem ext_iff {f g : alternating_map R M N ι} : f = g ↔ ∀ x, f x = g x :=
⟨λ h x, h ▸ rfl, λ h, ext h⟩

instance : has_coe (alternating_map R M N ι) (multilinear_map R (λ i : ι, M) N) :=
⟨λ x, x.to_multilinear_map⟩

@[simp, norm_cast] lemma coe_multilinear_map : ⇑(f : multilinear_map R (λ i : ι, M) N) = f := rfl

@[simp] lemma to_multilinear_map_eq_coe : f.to_multilinear_map = f := rfl

@[simp] lemma coe_multilinear_map_mk (f : (ι → M) → N) (h₁ h₂ h₃) :
  ((⟨f, h₁, h₂, h₃⟩ : alternating_map R M N ι) :  multilinear_map R (λ i : ι, M) N) = ⟨f, h₁, h₂⟩ :=
rfl

end coercions

/-!
### Simp-normal forms of the structure fields

These are expressed in terms of `⇑f` instead of `f.to_fun`.
-/
@[simp] lemma map_add (i : ι) (x y : M) :
  f (update v i (x + y)) = f (update v i x) + f (update v i y) :=
f.to_multilinear_map.map_add' v i x y

@[simp] lemma map_sub (i : ι) (x y : M') :
  g' (update v' i (x - y)) = g' (update v' i x) - g' (update v' i y) :=
g'.to_multilinear_map.map_sub v' i x y

@[simp] lemma map_smul (i : ι) (r : R) (x : M) :
  f (update v i (r • x)) = r • f (update v i x) :=
f.to_multilinear_map.map_smul' v i r x

@[simp] lemma map_eq_zero_of_eq (v : ι → M) {i j : ι} (h : v i = v j) (hij : i ≠ j) :
  f v = 0 :=
f.map_eq_zero_of_eq' v i j h hij

/-!
### Algebraic structure inherited from `multilinear_map`

`alternating_map` carries the same `add_comm_monoid`, `add_comm_group`, and `semimodule` structure
as `multilinear_map`
-/

instance : has_add (alternating_map R M N ι) :=
⟨λ a b,
  { map_eq_zero_of_eq' :=
      λ v i j h hij, by simp [a.map_eq_zero_of_eq v h hij, b.map_eq_zero_of_eq v h hij],
    ..(a + b : multilinear_map R (λ i : ι, M) N)}⟩

@[simp] lemma add_apply : (f + f') v = f v + f' v := rfl

instance : has_zero (alternating_map R M N ι) :=
⟨{map_eq_zero_of_eq' := λ v i j h hij, by simp,
  ..(0 : multilinear_map R (λ i : ι, M) N)}⟩

@[simp] lemma zero_apply : (0 : alternating_map R M N ι) v = 0 := rfl

instance : inhabited (alternating_map R M N ι) := ⟨0⟩

instance : add_comm_monoid (alternating_map R M N ι) :=
by refine {zero := 0, add := (+), ..};
   intros; ext; simp [add_comm, add_left_comm]

instance : has_neg (alternating_map R' M' N' ι) :=
⟨λ f,
  { map_eq_zero_of_eq' := λ v i j h hij, by simp [f.map_eq_zero_of_eq v h hij],
    ..(-(f : multilinear_map R' (λ i : ι, M') N')) }⟩

@[simp] lemma neg_apply (m : ι → M') : (-g') m = - (g' m) := rfl

instance : add_comm_group (alternating_map R' M' N' ι) :=
by refine {zero := 0, add := (+), neg := has_neg.neg, ..alternating_map.add_comm_monoid, ..};
   intros; ext; simp [add_comm, add_left_comm]

section semimodule

variables {S : Type*} [comm_semiring S] [algebra S R] [semimodule S N]
  [is_scalar_tower S R N]

instance : has_scalar S (alternating_map R M N ι) :=
⟨λ c f,
  { map_eq_zero_of_eq' := λ v i j h hij, by simp [f.map_eq_zero_of_eq v h hij],
    ..((c • f : multilinear_map R (λ i : ι, M) N)) }⟩

@[simp] lemma smul_apply (f : alternating_map R M N ι) (c : S) (m : ι → M) :
  (c • f) m = c • f m := rfl

/-- The space of multilinear maps over an algebra over `S` is a module over `S`, for the pointwise
addition and scalar multiplication. -/
instance : semimodule S (alternating_map R M N ι) :=
{ one_smul := λ f, ext $ λ x, one_smul _ _,
  mul_smul := λ c₁ c₂ f, ext $ λ x, mul_smul _ _ _,
  smul_zero := λ r, ext $ λ x, smul_zero _,
  smul_add := λ r f₁ f₂, ext $ λ x, smul_add _ _ _,
  add_smul := λ r₁ r₂ f, ext $ λ x, add_smul _ _ _,
  zero_smul := λ f, ext $ λ x, zero_smul _ _ }

end semimodule

/-!
### Theorems specific to alternating maps

Various properties of reordered and repeated inputs which follow from
`alternating_map.map_eq_zero_of_eq`.
-/

lemma map_update_self {i j : ι} (hij : i ≠ j) :
  f (function.update v i (v j)) = 0 :=
f.map_eq_zero_of_eq _ (by rw [function.update_same, function.update_noteq hij.symm]) hij

lemma map_update_update {i j : ι} (hij : i ≠ j) (m : M) :
  f (function.update (function.update v i m) j m) = 0 :=
f.map_eq_zero_of_eq _
  (by rw [function.update_same, function.update_noteq hij, function.update_same]) hij

lemma map_swap_add {i j : ι} (hij : i ≠ j) :
  f (v ∘ equiv.swap i j) + f v = 0 :=
begin
  rw equiv.comp_swap_eq_update,
  convert f.map_update_update v hij (v i + v j),
  simp [f.map_update_self _ hij,
        f.map_update_self _ hij.symm,
        function.update_comm hij (v i + v j) (v _) v,
        function.update_comm hij.symm (v i) (v i) v],
end

lemma map_add_swap {i j : ι} (hij : i ≠ j) :
  f v + f (v ∘ equiv.swap i j) = 0 :=
by { rw add_comm, exact f.map_swap_add v hij }

variable (g : alternating_map R M L ι)

lemma map_swap {i j : ι} (hij : i ≠ j) :
  g (v ∘ equiv.swap i j) = - g v  :=
eq_neg_of_add_eq_zero (g.map_swap_add v hij)

lemma map_perm [fintype ι] (v : ι → M) (σ : equiv.perm ι) :
  g (v ∘ σ) = (equiv.perm.sign σ : ℤ) • g v :=
begin
  apply equiv.perm.swap_induction_on' σ,
  { simp },
  { intros s x y hxy hI,
    simpa [g.map_swap (v ∘ s) hxy, equiv.perm.sign_swap hxy] using hI, }
end

lemma map_perm' [fintype ι] (v : ι → M) (σ : equiv.perm ι) :
  g (λ i, v (σ i)) = (equiv.perm.sign σ : ℤ) • g v :=
g.map_perm v σ

lemma map_congr_perm [fintype ι] (σ : equiv.perm ι) :
  g v = (equiv.perm.sign σ : ℤ) • g (v ∘ σ) :=
by { rw [g.map_perm, smul_smul], simp }

end alternating_map

open_locale big_operators

namespace multilinear_map

open equiv

variables [fintype ι]

private lemma alternization_map_eq_zero_of_eq_aux
  (m : multilinear_map R (λ i : ι, M) L)
  (v : ι → M) (i j : ι) (i_ne_j : i ≠ j) (hv : v i = v j) :
  ∑ (σ : perm ι), (σ.sign : ℤ) • m.dom_dom_congr σ v = 0 :=
finset.sum_involution
  (λ σ _, swap i j * σ)
  (λ σ _, begin
    convert add_right_neg (↑σ.sign • m.dom_dom_congr σ v),
    rw [perm.sign_mul, perm.sign_swap i_ne_j, ←neg_smul,
      multilinear_map.dom_dom_congr_apply, multilinear_map.dom_dom_congr_apply],
    congr' 2,
    { simp },
    { ext, simp [apply_swap_eq_self hv] },
  end)
  (λ σ _ _, (not_congr swap_mul_eq_iff).mpr i_ne_j)
  (λ σ _, finset.mem_univ _)
  (λ σ _, swap_mul_involutive i j σ)

/-- Produce an `alternating_map` out of a `multilinear_map`, by summing over all argument
permutations. -/
def alternatization : multilinear_map R (λ i : ι, M) L →+ alternating_map R M L ι :=
{ to_fun := λ m,
  { to_fun := λ v, ∑ (σ : perm ι), (σ.sign : ℤ) • m.dom_dom_congr σ v,
    map_add' := λ v i a b, by simp_rw [←finset.sum_add_distrib, multilinear_map.map_add, smul_add],
    map_smul' := λ v i c a, by simp_rw [finset.smul_sum, multilinear_map.map_smul, smul_comm],
    map_eq_zero_of_eq' := λ v i j hvij hij, alternization_map_eq_zero_of_eq_aux m v i j hij hvij },
  map_add' := λ a b, begin
    ext,
    simp only [
      finset.sum_add_distrib, smul_add, add_apply, dom_dom_congr_apply, alternating_map.add_apply,
      alternating_map.coe_mk],
  end,
  map_zero' := begin
    ext,
    simp only [
      dom_dom_congr_apply, alternating_map.zero_apply, finset.sum_const_zero, smul_zero,
      alternating_map.coe_mk, zero_apply]
  end }

lemma alternatization_apply (m : multilinear_map R (λ i : ι, M) L) (v : ι → M) :
  alternatization m v = ∑ (σ : perm ι), (σ.sign : ℤ) • m.dom_dom_congr σ v := rfl

end multilinear_map

namespace alternating_map

/-- Alternatizing a multilinear map that is already alternating results in a scale factor of `n!`,
where `n` is the number of inputs. -/
lemma to_multilinear_map_alternization [fintype ι] (a : alternating_map R M L ι) :
  a.to_multilinear_map.alternatization = nat.factorial (fintype.card ι) • a :=
begin
  ext,
  simp only [multilinear_map.alternatization_apply, map_perm, smul_smul, ←nat.smul_def, coe_mk,
    smul_apply, add_monoid_hom.coe_mk, finset.sum_const, coe_multilinear_map, one_smul,
    multilinear_map.dom_dom_congr_apply, int.units_coe_mul_self, to_multilinear_map_eq_coe,
    finset.card_univ, fintype.card_perm],
end

end alternating_map

-- TODO: move
namespace tensor_product

open_locale tensor_product

lemma smul_tmul_nat {R : Type*} {M : Type*} {N : Type*}
  [comm_semiring R] [add_comm_monoid M] [add_comm_monoid N] [semimodule R M] [semimodule R N]
  (r : ℕ) (m : M) (n : N) : ((r • m) ⊗ₜ[R] n) = m ⊗ₜ[R] r • n :=
begin
  induction r,
  { simp, },
  { rw [nat.smul_def, nat.smul_def, succ_nsmul, succ_nsmul, ←nat.smul_def, ←nat.smul_def],
    rw [add_tmul, tmul_add, r_ih], },
end

-- note: can be comm_semiring R after #5315
lemma smul_tmul_int {R : Type*} {M : Type*} {N : Type*}
  [comm_ring R] [add_comm_group M] [add_comm_group N] [semimodule R M] [semimodule R N]
  (r : ℤ) (m : M) (n : N) : ((r • m) ⊗ₜ[R] n) = m ⊗ₜ[R] r • n :=
by rw [←gsmul_eq_smul, module.gsmul_eq_smul_cast R, ←gsmul_eq_smul, module.gsmul_eq_smul_cast R,
  smul_tmul]

theorem smul_tmul'_int {R : Type*} {M : Type*} {N : Type*}
  [comm_ring R] [add_comm_group M] [add_comm_group N] [semimodule R M] [semimodule R N]
  (r : ℤ) (m : M) (n : N) :
  r • (m ⊗ₜ n : M ⊗[R] N) = (r • m) ⊗ₜ n :=
by rw [←gsmul_eq_smul, module.gsmul_eq_smul_cast R, ←gsmul_eq_smul, module.gsmul_eq_smul_cast R,
  smul_tmul']

theorem tmul_smul_int {R : Type*} {M : Type*} {N : Type*}
  [comm_ring R] [add_comm_group M] [add_comm_group N] [semimodule R M] [semimodule R N]
  (r : ℤ) (m : M) (n : N) :
  m ⊗ₜ (r • n) = r • (m ⊗ₜ n : M ⊗[R] N) :=
by rw [←gsmul_eq_smul, module.gsmul_eq_smul_cast R, ←gsmul_eq_smul, module.gsmul_eq_smul_cast R,
  tmul_smul]

#check tmul_smul

end tensor_product

-- TODO: move
namespace equiv

variables {α : Type*} [decidable_eq α]

/-- Right-multiplying a permutation with `swap i j` twice gives the original permutation.

  This specialization of `swap_mul_self` is useful when using cosets of permutations.
-/
@[simp]
lemma mul_swap_mul_self (i j : α) (σ : perm α) : (σ * equiv.swap i j) * equiv.swap i j = σ :=
by rw [mul_assoc, swap_mul_self, mul_one]

/-- A stronger version of `mul_left_injective` -/
@[simp]
lemma mul_swap_involutive (i j : α) : function.involutive (* (equiv.swap i j)) :=
mul_swap_mul_self i j

lemma mul_swap_eq_iff {i j : α} {σ : perm α} : σ * swap i j = σ ↔ i = j :=
⟨(assume h, have swap_id : swap i j = 1 := mul_left_cancel (trans h (one_mul σ).symm),
  by {rw [←swap_apply_right i j, swap_id], refl}),
(assume h, by erw [h, swap_self, mul_one])⟩

end equiv

section

namespace alternating_map

open_locale big_operators
open_locale tensor_product
-- /--
-- `mod_swap i j` contains permutations up to swapping `i` and `j`.

-- We use this to partition permutations in `matrix.det_zero_of_row_eq`, such that each partition
-- sums up to `0`.
-- -/
-- def mod_swap_sum {α β : Type*) [decidable_eq α] [decidable_eq β] (i : α) (j : β) :
--   setoid (sum_congr_subgroup α β) :=
-- ⟨λ σ τ, σ = τ ∨ σ = swap (sum.inl i) j * τ,
--  λ σ, or.inl (refl σ),
--  λ σ τ h, or.cases_on h (λ h, or.inl h.symm) (λ h, or.inr (by rw [h, swap_mul_self_mul])),
--  λ σ τ υ hστ hτυ, by cases hστ; cases hτυ; try {rw [hστ, hτυ, swap_mul_self_mul]}; finish⟩

-- instance {α : Type*} [fintype α] [decidable_eq α] (i j : α) : decidable_rel (mod_swap i j).r :=
-- λ σ τ, or.decidable

section coprod

variables {ιa ιb : Type*} [decidable_eq ιa] [decidable_eq ιb] [fintype ιa] [fintype ιb]

/-- The subgroup of permutations that do not exchange elements of α with elements of β. -/
def sum_congr_subgroup (α β : Type*) : subgroup (equiv.perm (α ⊕ β)) :=
{ carrier := λ σ, ∃ (sl : equiv.perm α) (sr : equiv.perm β), σ = equiv.perm.sum_congr sl sr,
  one_mem' := ⟨1, 1, equiv.perm.sum_congr_one.symm⟩,
  mul_mem' := λ σ₁ σ₂ ⟨sl₁₂, sr₁₂, h₁₂⟩ ⟨sl₂₃, sr₂₃, h₂₃⟩,
    ⟨sl₁₂ * sl₂₃, sr₁₂ * sr₂₃, h₂₃.symm ▸ h₁₂.symm ▸ equiv.perm.sum_congr_mul _ _ _ _⟩,
  inv_mem' := λ σ₁ ⟨sl, sr, h⟩, ⟨sl⁻¹, sr⁻¹, h.symm ▸ equiv.perm.sum_congr_inv _ _⟩ }

instance sum_congr_subgroup.left_rel_decidable
  {α β : Type*} [decidable_eq α] [decidable_eq β] [fintype α] [fintype β] :
  decidable_rel $ (quotient_group.left_rel (sum_congr_subgroup α β)).r :=
λ σ₁ σ₂, fintype.decidable_exists_fintype

-- /-- This is false :( -/
-- instance (α β : Type*) : subgroup.normal (sum_congr_subgroup α β) :=
-- { conj_mem := λ x xh g, begin
--     dsimp [sum_congr_subgroup] at *,
--     obtain ⟨sl, sr, rfl⟩ := xh,
--     existsi (_ * _),
--     existsi (_ * _),
--     rw ←equiv.perm.sum_congr_mul,
--   end }

#check quotient_group.quotient.group

/-- Elements which are considered equivalent if they differ only by swaps within α or β  -/
def mod_sum_congr (α β : Type*) := quotient_group.quotient $ sum_congr_subgroup α β

namespace mod_sum_congr

/-- `swap`, embedded in `mod_sum_congr` -/
def swap {α β : Type*} [decidable_eq α] [decidable_eq β] (i : α) (j : β) :
  mod_sum_congr α β :=
quot.mk _ (equiv.swap (sum.inl i) (sum.inr j))

-- /--
-- `mod_swap i j` contains permutations up to swapping `i` and `j`.

-- We use this to partition permutations in `matrix.det_zero_of_row_eq`, such that each partition
-- sums up to `0`.
-- -/
-- def mod_swap {α β : Type*} [decidable_eq α] [decidable_eq β] (i : α) (j : β) :
--   setoid (mod_sum_congr α β) :=
-- ⟨λ σ τ, σ = τ ∨ σ = swap i j * τ,
--  λ σ, or.inl (refl σ),
--  λ σ τ h, or.cases_on h (λ h, or.inl h.symm) (λ h, or.inr (by rw [h, swap_mul_self_mul])),
--  λ σ τ υ hστ hτυ, by cases hστ; cases hτυ; try {rw [hστ, hτυ, swap_mul_self_mul]}; finish⟩

-- instance {α : Type*} [fintype α] [decidable_eq α] (i j : α) : decidable_rel (mod_swap i j).r :=
-- λ σ τ, or.decidable

end mod_sum_congr

instance : fintype (mod_sum_congr ιa ιb) := quotient.fintype _


private def dom_coprod_aux
  {R : Type*} {M N₁ N₂ : Type*}
  [comm_ring R]
  [add_comm_group N₁] [semimodule R N₁]
  [add_comm_group N₂] [semimodule R N₂]
  [add_comm_monoid M] [semimodule R M]
  (a : alternating_map R M N₁ ιa) (b : alternating_map R M N₂ ιb)
  (v : ιa ⊕ ιb → M) : N₁ ⊗[R] N₂ :=
∑ σ : mod_sum_congr ιa ιb, σ.lift_on' (λ σ,
  (σ.sign : ℤ) •
    (multilinear_map.dom_coprod a.to_multilinear_map b.to_multilinear_map).dom_dom_congr σ v)
(λ σ₁ σ₂ h, begin
  simp only [multilinear_map.dom_dom_congr_apply,
             multilinear_map.dom_coprod_apply,
             algebra.lmul'_apply,
             to_multilinear_map_eq_coe,
             coe_multilinear_map],
  obtain ⟨sl, sr, h⟩ := h,
  rw inv_mul_eq_iff_eq_mul at h,
  have : ((σ₁ * equiv.sum_congr sl sr).sign : ℤ) = σ₁.sign * (sl.sign * sr.sign) := by simp,
  rw [h, this, mul_smul, mul_smul, units.smul_left_cancel, ←tensor_product.tmul_smul_int,
    tensor_product.smul_tmul'_int],
  simp only [sum.map_inr, equiv.perm.sum_congr_apply, sum.map_inl, function.comp_app,
             equiv.perm.coe_mul],
  rw [←a.map_congr_perm (λ i, v (σ₁ _)), ←b.map_congr_perm (λ i, v (σ₁ _))],
end)

/-- `swap`, embedded in `mod_sum_congr` -/
def apply_swapl {α β : Type*} [decidable_eq α] [decidable_eq β] (i j : α) :
  mod_sum_congr α β → mod_sum_congr α β :=
quotient.map' (λ σ, σ * equiv.swap (@sum.inl _ β i) (sum.inl j)) (λ σ₁ σ₂ h, begin
  dunfold has_equiv.equiv,
  dunfold setoid.r quotient_group.left_rel at ⊢ h,
  obtain ⟨sl, sr, h⟩ := h,
  rw [mul_inv_rev, mul_assoc, ←mul_assoc _ σ₂, h, equiv.swap_inv,
    ←equiv.perm.sum_congr_swap_one, equiv.perm.sum_congr_mul, equiv.perm.sum_congr_mul],
  exact ⟨_, _, rfl⟩
end)

/-- `swap`, embedded in `mod_sum_congr` -/
def mod_sum_congr.swap_mul {α β : Type*} [decidable_eq α] [decidable_eq β] (i j : α ⊕ β) :
  mod_sum_congr α β → mod_sum_congr α β :=
quotient.map' (λ σ, equiv.swap i j * σ) (λ σ₁ σ₂ h, begin
  dunfold has_equiv.equiv setoid.r quotient_group.left_rel,
  rw [mul_inv_rev, mul_assoc, ←mul_assoc _ _ σ₂, inv_mul_self, one_mul],
  exact h
end)

lemma mod_sum_congr.swap_mul_involutive  {α β : Type*} [decidable_eq α] [decidable_eq β]
  (i j : α ⊕ β) : function.involutive (mod_sum_congr.swap_mul i j) :=
begin
  rintros ⟨σ⟩,
  exact _root_.congr_arg (quot.mk _) (equiv.swap_mul_involutive i j σ),
end

lemma is_inr_of_not_is_inl {α β : Type*} [decidable_eq α] [decidable_eq β]
  {i : α ⊕ β}
  (h : ¬∃ i', sum.inl i' = i) : ∃ i', sum.inr i' = i :=
begin
  rw [not_exists] at h,
  cases i,
  exact (h i rfl).elim,
  exact ⟨i, rfl⟩
end

lemma not_moves_from_left {α β : Type*} [decidable_eq α] [decidable_eq β] {σ : equiv.perm (α ⊕ β)}
  {i : α ⊕ β}
  (h : ¬∃ i', σ (sum.inl i') = i) : ∃ i', σ (sum.inr i') = i :=
begin
  rw [not_exists] at h,
  cases h' : σ⁻¹ i,
  { exfalso, apply h val, rw ←h', simp, },
  { use val, rw ←h', simp, }
end

@[simp] lemma quotient.lift_on'_beta {α β : Type*} {s : setoid α} (f : α → β) (h) (x : α) :
  (@quotient.mk' _ s x).lift_on' f h = f x := rfl

/--
Cases on each summand:

* `⇑σ (sum.inl i') = i ∧ ⇑σ (sum.inl j') = j`,
      `⇑a (λ (i : ιa), v (⇑σ (sum.inl i))) = 0`
* `⇑σ (sum.inr i') = i ∧ ⇑σ (sum.inr j') = j`,
      `⇑b (λ (i : ιa), v (⇑σ (sum.inr i))) = 0`
* `⇑σ (sum.inr i') = i ∧ ⇑σ (sum.inl j') = j`,
  `⇑σ (sum.inl i') = i ∧ ⇑σ (sum.inr j') = j`
    ab (σ) + ab (σ ∘ swap) = 0
-/
private lemma dom_coprod_aux_eq_zero_if_eq
  {R : Type*} {M N₁ N₂ : Type*}
  [comm_ring R]
  [add_comm_group N₁] [semimodule R N₁]
  [add_comm_group N₂] [semimodule R N₂]
  [add_comm_monoid M] [semimodule R M]
  (a : alternating_map R M N₁ ιa) (b : alternating_map R M N₂ ιb)
  (v : ιa ⊕ ιb → M) (i j : ιa ⊕ ιb) (h : v i = v j) (hij : i ≠ j) :
  dom_coprod_aux a b v = 0 :=
begin
  unfold dom_coprod_aux,
  dsimp only,
  simp only [linear_map.comp_multilinear_map_dom_dom_congr,
              linear_map.comp_multilinear_map_apply,
              multilinear_map.dom_dom_congr_apply,
              multilinear_map.dom_coprod_apply,
              algebra.lmul'_apply,
              to_multilinear_map_eq_coe,
              coe_multilinear_map],
  apply finset.sum_involution
    (λ σ _, mod_sum_congr.swap_mul i j σ)
    (λ σ, _)
    (λ σ, _)
    (λ σ _, finset.mem_univ _)
    (λ σ _, mod_sum_congr.swap_mul_involutive i j σ),
  { apply σ.induction_on' (λ σ, _),
    intro _,
    dsimp only [quotient.lift_on'_beta, mod_sum_congr.swap_mul, quotient.map'_mk'],
    rw [equiv.perm.sign_mul, equiv.perm.sign_swap hij],
    simp only [one_mul, units.neg_mul, function.comp_app, neg_smul, equiv.perm.coe_mul, units.coe_neg],
    convert add_right_neg _;
    { ext k, rw equiv.apply_swap_eq_self h },
    },
  { apply σ.induction_on' (λ σ, _),
    intro _,
    dsimp only [quotient.lift_on'_beta, mod_sum_congr.swap_mul, quotient.map'_mk'],
    intro hnz,
    by_cases hsw : (∃ il, σ (sum.inl il) = i) ↔ (∃ jl, σ (sum.inl jl) = j),
    { exfalso,
      apply hnz,
      convert smul_zero _,
      obtain (⟨⟨i', hi'⟩, ⟨j', hj'⟩⟩ | ⟨hi', hj'⟩) := iff_iff_and_or_not_and_not.mp hsw;
      [ convert tensor_product.zero_tmul _ _, convert tensor_product.tmul_zero _ _],
      { rw [←hi', ←hj'] at h,
        refine a.map_eq_zero_of_eq _ h _,
        intro hij',
        apply hij,
        rw [←hi', ←hj', hij'],},
      { obtain ⟨i', hi'⟩ := not_moves_from_left hi',
        obtain ⟨j', hj'⟩ := not_moves_from_left hj',
        rw [←hi', ←hj'] at h,
        refine b.map_eq_zero_of_eq _ h _,
        intro hij',
        apply hij,
        rw [←hi', ←hj', hij'], },
      },
    { intro h,
      obtain ⟨sl, sr, h⟩ := quotient.eq'.mp h,
      obtain (⟨hi', ⟨j', hj'⟩⟩ | ⟨hi', hj'⟩) := iff_iff_and_or_not_and_not.mp (not_iff.mp hsw),
      work_on_goal 0 {
        obtain ⟨i', hi'⟩ := not_moves_from_left hi', },
      work_on_goal 1 {
        obtain ⟨i', hi'⟩ := not_not.mp hi',
        obtain ⟨j', hj'⟩ := not_moves_from_left hj', },
      all_goals {
        rw [←hi', ←hj', ←equiv.mul_swap_eq_swap_mul, mul_inv_rev, equiv.swap_inv,
          inv_mul_cancel_right] at h,
         },
      { replace h := _root_.congr_arg (λ e : equiv.perm (ιa ⊕ ιb), e (sum.inr i')) h,
        simpa using h, },
      { replace h := _root_.congr_arg (λ e : equiv.perm (ιa ⊕ ιb), e (sum.inl i')) h,
        simpa using h, }, }
    },
end

/-- Like `multilinear_map.dom_coprod`, but ensures the result is also alternating.

Note this is the same as `(multilinear_map.dom_coprod a b).alternize / (card ιa)! / (card ιb)!`.-/
def dom_coprod
  {R : Type*} {M N₁ N₂ : Type*}
  [comm_ring R]
  [add_comm_group N₁] [semimodule R N₁]
  [add_comm_group N₂] [semimodule R N₂]
  [add_comm_monoid M] [semimodule R M]
  (a : alternating_map R M N₁ ιa) (b : alternating_map R M N₂ ιb) :
  alternating_map R M (N₁ ⊗[R] N₂) (ιa ⊕ ιb) :=
{ to_fun := dom_coprod_aux a b,
  map_add' := λ v i p q, begin
    dsimp only [dom_coprod_aux],
    simp_rw [←finset.sum_add_distrib, multilinear_map.map_add, smul_add],
    congr' 1,
    ext σ',
    obtain ⟨σ, rfl⟩ := quot.exists_rep σ',
    refl,
  end,
  map_smul' := λ v i c p, begin
    dsimp only [dom_coprod_aux],
    simp_rw [finset.smul_sum, multilinear_map.map_smul, smul_comm],
    congr' 1,
    ext σ',
    obtain ⟨σ, rfl⟩ := quot.exists_rep σ',
    refl,
  end,
  map_eq_zero_of_eq' := dom_coprod_aux_eq_zero_if_eq a b }

-- ### Old version, before generalizing to arbitrary index types
--
-- def mul_fin {n m} {R : Type*} {M N : Type*}
--   [comm_semiring R] [ring N] [algebra R N] [add_comm_monoid M] [semimodule R M]
--   (a : alternating_map R M N (fin m)) (b : alternating_map R M N (fin n)) :
--   alternating_map R M N (fin (m + n)) :=
-- { to_fun :=
--     let ab := (algebra.lmul' R).comp_multilinear_map
--       $ multilinear_map.dom_coprod a.to_multilinear_map b.to_multilinear_map in
--     λ (v : fin (m + n) → M),
--     ∑ σ : shuffle m n, (σ.to_perm.sign : ℤ) • (ab.dom_dom_congr σ.val) v,
--   map_add' := λ v i p q, by simp_rw [←finset.sum_add_distrib, ←smul_add, multilinear_map.map_add],
--   map_smul' := λ v i c p, by simp_rw [finset.smul_sum, ←smul_comm, multilinear_map.map_smul],
--   map_eq_zero_of_eq' := λ v i j h hij, begin
--     sorry
--   end }

end coprod

end alternating_map

end

∀