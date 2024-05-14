use ark_bn254::{Fr, G1Projective};
use ark_ec::PrimeGroup;
use ark_ff::UniformRand; // Provides the rand trait for field elements
use ark_serialize::CanonicalSerialize;
use merlin::Transcript; // Assuming you're using the merlin crate for transcripts
use libspartan::nizk::bullet::BulletReductionProof;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize inputs for the prove function.
    // These would be your actual inputs for the proof.
    let mut rng = rand::thread_rng();

    let transcript = &mut Transcript::new(b"BulletProofs Example");
    let Q: G1Projective = G1Projective::generator();
    let G_vec: Vec<G1Projective> = vec![G1Projective::generator(); 2]; // Example
    let H: G1Projective = G1Projective::generator();
    let a_vec: Vec<Fr> = vec![Fr::rand(&mut rng); 2]; // Example
    let b_vec: Vec<Fr> = vec![Fr::rand(&mut rng); 2]; // Example
    let blind: Fr = Fr::rand(&mut rng);
    let blinds_vec: Vec<(Fr, Fr)> = vec![(Fr::rand(&mut rng), Fr::rand(&mut rng)); 2]; // Example

    // Call the prove function.
    let (proof, gamma_hat, a, b, g, blind_fin) = BulletReductionProof::<ark_bn254::G1Projective>::prove(
        transcript,
        &Q,
        &G_vec,
        &H,
        &a_vec,
        &b_vec,
        &blind,
        &blinds_vec,
    );

    // Serialize the outputs to byte arrays.
    let mut proof_bytes = Vec::new();
    proof.serialize_uncompressed(&mut proof_bytes)?;
    let mut gamma_hat_bytes = Vec::new();
    gamma_hat.serialize_uncompressed(&mut gamma_hat_bytes)?;
    let mut a_bytes = Vec::new();
    CanonicalSerialize::serialize_uncompressed(&a, &mut a_bytes)?;
    let mut b_bytes = Vec::new();
    CanonicalSerialize::serialize_uncompressed(&b, &mut b_bytes)?;
    let mut g_bytes = Vec::new();
    g.serialize_uncompressed(&mut g_bytes)?;
    let mut blind_fin_bytes = Vec::new();
    CanonicalSerialize::serialize_uncompressed(&blind_fin, &mut blind_fin_bytes)?;

    // Print the serialized byte arrays to the terminal.
    print!("Prover inputs:");
    println!("Input Q: {}", Q.to_string());
    println!("Input G_vec:");
    for point in G_vec {
        println!("\t\tpoint: {}", point.to_string());
    }
    println!("Input H: {}", H.to_string());
    println!("Input a_vec:");
    for scalar in a_vec {
        println!("\t\ta scalar: {}", scalar);
    }
    println!("Input b_vec:");
    for scalar in b_vec {
        println!("\t\tb scalar: {}", scalar);
    }
    println!("Input blind: {}", blind);
    println!("Input blind_vec:");
    for tuple in blinds_vec {
        println!("\t\tblinds: {:?}", tuple);
    }
    println!();
    println!("Prover outputs:");
    println!("L_vec:");
    for point in proof.L_vec {
        println!("\t\tpoint: {}", point.to_string());
    }
    println!("R_vec:");
    for point in proof.R_vec {
        println!("\t\tpoint: {}", point.to_string());
    }
    println!("Gamma hat: {}", gamma_hat.to_string());
    println!("a: {}", a);
    println!("b: {}", b);
    println!("g: {}", g.to_string());
    println!("blind fin: {}", blind_fin);

    return Result::Ok(());
}